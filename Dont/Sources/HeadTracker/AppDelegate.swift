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
        menu.addItem(NSMenuItem(title: "Quit HeadTracker", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
