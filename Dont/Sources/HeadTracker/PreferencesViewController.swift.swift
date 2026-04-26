//
//  PreferencesViewController.swift.swift
//  Dont
//
//  Created by Eisvogel, Bernhard on 26.04.26.
//

import AppKit

final class PreferencesViewController: NSViewController {

    override func loadView() {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 300))

        let checkbox = NSButton(checkboxWithTitle: "Enable feature", target: nil, action: nil)
        checkbox.frame.origin = CGPoint(x: 20, y: 200)

        view.addSubview(checkbox)
        self.view = view
    }
}
