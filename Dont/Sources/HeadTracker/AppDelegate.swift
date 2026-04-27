import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var tracker: HeadTracker?
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched in background")
        tracker = HeadTracker()

        // Create Status Bar Item to allow quitting the background app
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "👁👁"
        }

        let menu = NSMenu()
        
        let toggleFallAsleep = NSMenuItem(
            title: "Toggle Sleep Notifier",
            action: #selector(toggleFallAsleepTracking(_:)),
            keyEquivalent: "s"
        )
        let toggleTouchFace = NSMenuItem(
            title: "Toggle Touch Face Notifier",
            action: #selector(toggleTouchFaceTracking(_:)),
            keyEquivalent: "f"
        )
        toggleFallAsleep.target = self
        toggleTouchFace.target = self

        let isEnabledSleep = UserDefaults.standard.bool(forKey: fallAsleepKey)
        toggleFallAsleep.state = isEnabledSleep ? .on : .off

        let isEnabledFace = UserDefaults.standard.bool(forKey: touchFaceKey)
        toggleTouchFace.state = isEnabledFace ? .on : .off
       
       
       menu.addItem(toggleTouchFace)
       menu.addItem(toggleFallAsleep)
       menu.addItem(NSMenuItem.separator())
       menu.addItem(NSMenuItem(title: "Quit Dont! (don't quit ;) )", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    
    @objc func toggleFallAsleepTracking(_ sender: NSMenuItem) {
        let newValue = (sender.state != .on)
        sender.state = newValue ? .on : .off
        
        UserDefaults.standard.set(newValue, forKey: fallAsleepKey)
    }
    
    @objc func toggleTouchFaceTracking(_ sender: NSMenuItem) {
        let newValue = (sender.state != .on)
        sender.state = newValue ? .on : .off
        
        UserDefaults.standard.set(newValue, forKey: touchFaceKey)
    }
}
