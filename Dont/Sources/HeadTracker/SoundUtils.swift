import AppKit

var currentSound: NSSound?

func stopWav() {
    // Stop the currently playing audio player
    currentSound?.stop()
    currentSound = nil
}

var timeNextSoundNotification = Date.distantPast // I dont want stuff to be said at the same time

func playWav(named fileName: String) {
    let now = Date()
    if (now>timeNextSoundNotification){
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "m4a") else {
            print("Sound not found: \(fileName)")
            return
        }
        stopWav()
        currentSound = NSSound(contentsOf: url, byReference: true)
        currentSound?.play()
        timeNextSoundNotification = now.advanced(by: currentSound?.duration ?? 0)
    }
}

func pressSpace() {
    // Maybe we can do somehting fun with this later
    let source = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x31, keyDown: true)
    let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: 0x31, keyDown: false)

    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
}
