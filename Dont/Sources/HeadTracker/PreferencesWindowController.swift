//
//  PreferencesWindowController.swift
//  Dont
//
//  Created by Eisvogel, Bernhard on 26.04.26.
//

import AppKit

final class PreferencesWindowController: NSWindowController {

    convenience init() {
        let vc = PreferencesViewController()

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.contentViewController = vc
        window.title = "Preferences"

        self.init(window: window)
    }
}
