//
//  TavilyHandler.swift
//  Dont
//
//  Created by Eisvogel, Bernhard on 26.04.26.
//

import Foundation

let PYTHON_INTERPRETER:String = "/opt/anaconda3/bin/python"

// This is still a somewhat bad version of

func runTavily(query: String = "pleasant dolphin sounds") {
    let process = Process()
    
    process.currentDirectoryURL = URL(fileURLWithPath: "/Users/bernhae45/Documents/EyesOpen/Dont/tavily")
    process.executableURL = URL(fileURLWithPath: "/opt/anaconda3/bin/python")
    
    process.environment = [
        "PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/opt/anaconda3/bin"
    ]

    let scriptPath = "tavily_test.py"
    process.arguments = [scriptPath, query, "False"]

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe   // optional but useful for debugging

    do {
        try process.run()
        print("Python script started")

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print("Python output:\n\(output)")
        }

    } catch {
        print("Failed to run script: \(error)")
    }
}
