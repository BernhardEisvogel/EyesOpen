import AppKit


// Entry point – all classes are defined in their respective source files.
let app = NSApplication.shared
let delegate = AppDelegate()


let fallAsleepKey = "fallAsleepPersistentKey"
let touchFaceKey = "touchFacePersistentKey"


app.delegate = delegate
app.run()
