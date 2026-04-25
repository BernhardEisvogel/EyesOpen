import Cocoa
import AVFoundation
import Vision
import UserNotifications

class HeadTracker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    var lastNotificationTime = Date.distantPast
    
    override init() {
        super.init()
        setupPermissions()
    }
    
    func setupPermissions() {
        // Request Notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if !granted {
                print("Notification permission denied.")
            }
        }
        
        // Request Camera permission
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
        let request = VNDetectFaceLandmarksRequest { [weak self] req, err in
            if let results = req.results as? [VNFaceObservation], let firstFace = results.first {
                self?.handleFace(observation: firstFace)
            }
        }
        
        do {
            try handler.perform([request])
        } catch {
            print("Vision request failed: \(error)")
        }
    }
    
    func handleFace(observation: VNFaceObservation) {
        guard let yaw  = observation.yaw else { return }
        guard let roll = observation.roll else { return }

        let yawValue = yaw.doubleValue
        let rollValue = roll.doubleValue
        
        // In Vision's coordinate space for yaw (when orientation .up is specified):
        // Usually, turning the head towards the right (user's right) yields negative yaw values
        // Turning to the left yields positive. We configure < -0.4 as "Right".
        if rollValue < -0.4 {
            triggerNotification(direction: "Right")
        }
    }
    
    func triggerNotification(direction: String) {
        let now = Date()
        // Send a notification at most once every 5 seconds to avoid spam
        if now.timeIntervalSince(lastNotificationTime) > 5.0 {
            lastNotificationTime = now
            
            let content = UNMutableNotificationContent()
            content.title = "Head turn detected!"
            content.body = "You turned your head to the \(direction)."
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error posting notification: \(error)")
                } else {
                    print("Notification posted: \(direction)")
                }

            print("Head turned \(direction)")
            
        }
        }
    }
}





        
class AppDelegate: NSObject, NSApplicationDelegate {
    var tracker: HeadTracker?
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched in background")
        tracker = HeadTracker()
        
        // Create Status Bar Item to allow quitting the background app
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "👁📱" // Eye & Phone icon, or any generic icon
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit HeadTracker", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
