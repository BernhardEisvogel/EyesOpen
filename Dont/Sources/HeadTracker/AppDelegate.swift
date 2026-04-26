import Cocoa

var isTrackingEnabled = true

class AppDelegate: NSObject, NSApplicationDelegate {

    var tracker: HeadTracker?
    var statusItem: NSStatusItem?

    // 👇 Keep a strong reference so the window doesn’t disappear
    private var prefsWindow: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("App launched in background")

        tracker = HeadTracker()
        prefsWindow = PreferencesWindowController()
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.title = "👁👁"
        }

        runTavily()
        
        let menu = NSMenu()

        // 👇 Preferences item
        menu.addItem(NSMenuItem(
            title: "Preferences",
            action: #selector(openPreferences),
            keyEquivalent: ","
        ))

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(
            title: "Quit HeadTracker",
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc func openPreferences() {
        prefsWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
