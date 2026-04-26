//
//  TavilyHandler.swift
//  Dont
//
//  Created by Eisvogel, Bernhard on 26.04.26.
//

import Foundation

// This line might have to be changed depending on the system. This will also be improved later.

let PYTHON_INTERPRETER:String = "/opt/anaconda3/bin/python"

// This is still a somewhat bad version, but it does run

func runTavily(query: String = "pleasant dolphin sounds") {
    let process = Process()
    
    if let resourcePath = Bundle.main.resourcePath {
        process.currentDirectoryURL = URL(fileURLWithPath: resourcePath)
    } else {
        // Fallback to a relative path if bundle is not available (e.g. during development)
        let currentPath = FileManager.default.currentDirectoryPath
        process.currentDirectoryURL = URL(fileURLWithPath: currentPath).appendingPathComponent("Sources/HeadTracker/Resources")
    }
    
    // Try to find python in common locations or use the one in PATH
    let pythonPath = "/usr/bin/python3" // Default macOS python3
    process.executableURL = URL(fileURLWithPath: pythonPath)
    
    process.environment = [
        "PATH": "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/opt/anaconda3/bin"
    ]

    let scriptPath = "tavily_test.py"
    process.arguments = [scriptPath, query, "True"]

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
