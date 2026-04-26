import AppKit

var currentSound: NSSound?

func stopWav() {
    // Stop the currently playing audio player
    currentSound?.stop()
    currentSound = nil
}

var timeNextSoundNotification = Date.distantPast // I dont wan tstuff to be said at the same time

func playTavilySounds(){
    // runTavily(query: "scary jumpscare sounds")
    let chocie:Int = Int.random(in: 0..<3)
    if chocie == 0 {
        playWav(named: "tavily_1", ext:  "mp3")
    } else if chocie == 1 {
        playWav(named: "tavily_2", ext:  "mp3")
    } else {
        playWav(named: "tavily_3", ext:  "mp3")
    }
}

func playWav(named fileName: String, ext: String = "m4a") {

    let now = Date()
    if (now>timeNextSoundNotification){
        let url = Bundle.main.url(forResource: fileName, withExtension: ext) ?? Bundle.main.url(forResource: fileName, withExtension: ext)
        guard let soundURL = url else {
            print("Sound not found: \(fileName)")
            return
        }
        stopWav()
        currentSound = NSSound(contentsOf: soundURL, byReference: true)
        currentSound?.play()
        timeNextSoundNotification = now.advanced(by: currentSound?.duration ?? 0)
    }
}

func playWav(url: URL) {
    let now = Date()
    if (now > timeNextSoundNotification) {
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
