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
        menu.addItem(NSMenuItem(title: "Set Reminder...", action: #selector(configureTTSText), keyEquivalent: "t"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit HeadTracker", action: #selector(quitApp), keyEquivalent: "q"))
        statusItem?.menu = menu

        setupEditMenu()
    }

    func setupEditMenu() {
        let mainMenu = NSMenu()
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        
        editMenuItem.submenu = editMenu
        NSApp.mainMenu = mainMenu
    }

    @objc func configureTTSText() {
        // Small delay to allow the menu to close before activating the app
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showConfigurationAlert()
        }
    }

    func showConfigurationAlert() {
        let currentPolicy = NSApp.activationPolicy()
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        let alert = NSAlert()
        alert.messageText = "Configure Alert Texts"
        alert.informativeText = "Enter the text you want Gradium to speak for each alert:"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let stackView = NSStackView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8

        let handFaceLabel = NSTextField(labelWithString: "Hand Touching Face Alert:")
        let handFaceField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        handFaceField.stringValue = UserDefaults.standard.string(forKey: "HandFaceAlertText") ?? "Don't touch your face!"

        let headDownLabel = NSTextField(labelWithString: "Head Down Alert:")
        let headDownField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        headDownField.stringValue = UserDefaults.standard.string(forKey: "HeadDownAlertText") ?? "Keep your head up!"
        
        let noiseLabel = NSTextField(labelWithString: "Sound description:")
        let noiseField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        noiseField.stringValue = UserDefaults.standard.string(forKey: "noiseText") ?? "scary jump scare sounds!"

        handFaceField.nextKeyView = headDownField
        
        stackView.addArrangedSubview(handFaceLabel)
        stackView.addArrangedSubview(handFaceField)
        
        stackView.addArrangedSubview(headDownLabel)
        stackView.addArrangedSubview(headDownField)
        
        stackView.addArrangedSubview(noiseLabel)
        stackView.addArrangedSubview(noiseField)

        alert.accessoryView = stackView
        alert.layout()
        
        // Ensure the window is key and the field is first responder
        alert.window.makeKeyAndOrderFront(nil)
        alert.window.makeFirstResponder(handFaceField)

        let response = alert.runModal()
        NSApp.setActivationPolicy(currentPolicy)

        if response == .alertFirstButtonReturn {
            UserDefaults.standard.set(handFaceField.stringValue, forKey: "HandFaceAlertText")
            UserDefaults.standard.set(headDownField.stringValue, forKey: "HeadDownAlertText")
            print("Saved new alert texts.")
            
            // Delete old sounds to force re-generation
            let handFaceURL = FileManager.default.temporaryDirectory.appendingPathComponent("hand_face_alert.wav")
            let headDownURL = FileManager.default.temporaryDirectory.appendingPathComponent("head_down_alert.wav")
            try? FileManager.default.removeItem(at: handFaceURL)
            try? FileManager.default.removeItem(at: headDownURL)
            
            // Pre-generate the sounds
            Task {
                await pregenerateSounds()
            }
        }
    }

    func pregenerateSounds() async {
        let handFaceText = UserDefaults.standard.string(forKey: "HandFaceAlertText") ?? "Don't touch your face!"
        let headDownText = UserDefaults.standard.string(forKey: "HeadDownAlertText") ?? "Keep your head up!"
        let noiseText = UserDefaults.standard.string(forKey: "noiseText") ?? "Scary jump scare noises"
        
        do {
            print("Pre-generating hand-face sound...")
            let handFaceData = try await GradiumService.shared.generateSpeech(text: handFaceText)
            let handFaceURL = FileManager.default.temporaryDirectory.appendingPathComponent("hand_face_alert.wav")
            try handFaceData.write(to: handFaceURL)
            
            print("Pre-generating head-down sound...")
            let headDownData = try await GradiumService.shared.generateSpeech(text: headDownText)
            let headDownURL = FileManager.default.temporaryDirectory.appendingPathComponent("head_down_alert.wav")
            try headDownData.write(to: headDownURL)
            
            print("Generating Tavily sounds")
            runTavily(query: noiseText)
            
            print("Sounds pre-generated successfully.")
        } catch {
            print("Error pre-generating sounds: \(error)")
        }
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
