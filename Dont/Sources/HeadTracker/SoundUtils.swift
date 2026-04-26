import AppKit

var currentSound: NSSound?

func stopWav() {
    currentSound?.stop()
    currentSound = nil
}

func playWav(named fileName: String) {
    guard let url = Bundle.main.url(forResource: fileName, withExtension: "m4a") else {
        print("Sound not found: \(fileName)")
        return
    }

    currentSound = NSSound(contentsOf: url, byReference: true)
    currentSound?.play()
}

func pressSpace() {
    let source = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x31, keyDown: true)
    let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: 0x31, keyDown: false)

    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
}
