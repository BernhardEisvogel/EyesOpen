import AVFoundation
import Vision

class HeadTracker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    var lastNotificationTime = Date.distantPast
    var lastHandFaceNotificationTime = Date.distantPast

    // Latest face bounding box from the face request (Vision normalised coords, origin bottom-left)
    var latestFaceBoundingBox: CGRect? = nil
    let faceBoundingBoxLock = NSLock()

    override init() {
        super.init()
        setupPermissions()
    }

    func setupPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupCamera()
                } else {
                    print("Camera access denied.")
                }
            }
        default:
            print("Camera access not authorized.")
        }
    }

    func setupCamera() {
        session.sessionPreset = .low
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("No video device found")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input) }

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]

            if session.canAddOutput(output) { session.addOutput(output) }

            session.startRunning()
            print("Started camera session...")
        } catch {
            print("Error setting up camera: \(error)")
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // Orientation .up represents standard camera feed orientation
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        // --- Face detection request ---
        let faceRequest = VNDetectFaceRectanglesRequest { [weak self] req, _ in
            guard let self = self else { return }
            if let results = req.results as? [VNFaceObservation], let firstFace = results.first {
                self.faceBoundingBoxLock.lock()
                self.latestFaceBoundingBox = firstFace.boundingBox
                self.faceBoundingBoxLock.unlock()
                self.handleFace(observation: firstFace)
            } else {
                self.faceBoundingBoxLock.lock()
                self.latestFaceBoundingBox = nil
                self.faceBoundingBoxLock.unlock()
            }
        }

        // --- Hand pose request ---
        let handRequest = VNDetectHumanHandPoseRequest { [weak self] req, _ in
            guard let self = self else { return }
            guard let observations = req.results as? [VNHumanHandPoseObservation],
                  !observations.isEmpty else { return }

            self.faceBoundingBoxLock.lock()
            let faceBBox = self.latestFaceBoundingBox
            self.faceBoundingBoxLock.unlock()

            guard let faceBBox = faceBBox else { return }

            // Expand the face bounding box slightly to be more sensitive near edges
            let padding: CGFloat = 0.04
            let expandedFace = faceBBox.insetBy(dx: -padding, dy: -padding)

            // Fingertip joint names we care about
            let fingertips: [VNHumanHandPoseObservation.JointName] = [
                .indexTip, .middleTip, .ringTip, .littleTip, .thumbTip,
                .indexDIP, .middleDIP, .ringDIP, .littleDIP
            ]

            for hand in observations {
                for joint in fingertips {
                    if let point = try? hand.recognizedPoint(joint),
                       point.confidence > 0.5 {
                        // Vision uses bottom-left origin for both face bbox and hand points
                        let handPoint = CGPoint(x: point.x, y: point.y)
                        if expandedFace.contains(handPoint) {
                            self.triggerHandFaceNotification()
                            return
                        }
                    }
                }
            }
        }
        handRequest.maximumHandCount = 2

        do {
            try handler.perform([faceRequest, handRequest])
        } catch {
            print("Vision request failed: \(error)")
        }
    }

    func handleFace(observation: VNFaceObservation) {

        guard let pitch = observation.pitch else { return }

        let pitchValue = pitch.doubleValue

        if pitchValue < -0.15 {
            triggerHeadDownNotification(direction: "up")
        } else if pitchValue > 0.4 {
            triggerHeadDownNotification(direction: "down")
        }
    }

    /// Called when a hand fingertip overlaps the face bounding box.
    func triggerHandFaceNotification() {
        let now = Date()
        // Cooldown: alert at most once every 0.7 seconds
        lastHandFaceNotificationTime = now
        print("Hand touching face detected!")
        playWav(named: "dont_touch_your_face")
    }

    func triggerHeadDownNotification(direction: String) {
        if direction == "down" {
            if Int.random(in: 1...2) == 1 {
                playWav(named: "mmmrmmm")
            } else {
                playWav(named: "dont_fall_asleep")
            }
        }
        
    }
}
