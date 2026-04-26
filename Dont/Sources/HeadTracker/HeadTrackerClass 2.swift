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
        guard let yaw   = observation.yaw else { return }
        guard let roll  = observation.roll else { return }
        guard let pitch = observation.pitch else { return }

        let _ = yaw.doubleValue
        let _ = roll.doubleValue
        let pitchValue = pitch.doubleValue

        if pitchValue < -0.15 {
            triggerNotification(direction: "up")
        } else if pitchValue > 0.4 {
            //triggerNotification(direction: "down")
            playTavilySounds()
        }
    }

    /// Called when a hand fingertip overlaps the face bounding box.
    func triggerHandFaceNotification() {
        let now = Date()
        // Cooldown: alert at most once every 0.7 seconds
        lastHandFaceNotificationTime = now
        print("Hand touching face detected!")
        
        // Randomly choose between TTS and local sound
        if Int.random(in: 1...15) < 10 {
            let text = UserDefaults.standard.string(forKey: "HandFaceAlertText") ?? "Don't touch your face!"
            triggerGradiumSound(text: text, filename: "hand_face_alert.wav")
        } else {
            playWav(named: "dont_touch_your_face")
        }
    }

    func triggerGradiumSound(text: String, filename: String) {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        // Check if file exists, if so play it immediately for better responsiveness
        if FileManager.default.fileExists(atPath: fileURL.path) {
            DispatchQueue.main.async {
                playWav(url: fileURL)
            }
            return
        }
        
        // If not, generate it on the fly
        Task {
            do {
                let data = try await GradiumService.shared.generateSpeech(text: text)
                try data.write(to: fileURL)
                
                DispatchQueue.main.async {
                    playWav(url: fileURL)
                }
            } catch {
                print("Error generating alert for \(filename): \(error)")
                // Fallback to local sound if TTS fails
                DispatchQueue.main.async {
                    if filename == "hand_face_alert.wav" {
                        playWav(named: "dont_touch_your_face")
                    } else {
                        playWav(named: "dont_fall_asleep")
                    }
                }
            }
        }
    }


    func triggerNotification(direction: String) {
        //print("Head turned \(direction)")
        if direction == "down" {
            
            let rand = Int.random(in: 1...10)
            print("Head down detected!", rand)
            if rand < 9 {
                let text = UserDefaults.standard.string(forKey: "HeadDownAlertText") ?? "Keep your head up!"
                triggerGradiumSound(text: text, filename: "head_down_alert.wav")
            }
            else if rand == 9 {
                playWav(named: "mmmrmmm")
            } else {
                playWav(named: "dont_fall_asleep")
            }
        }
    }
}
