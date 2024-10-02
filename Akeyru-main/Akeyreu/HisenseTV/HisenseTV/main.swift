//
//  main.swift
//  HisenseTV
//
//  Created by Asher Amey on 8/9/24.
//

import Foundation

// Define the IP and Port of your Fire TV
let fireTVIP = "192.168.1.100"
let fireTVPort = 5555

// Define the path to your private key for ADB authentication
let privateKeyPath = "/Users/ajrudd/.android/adbkey"  

// Load the private key for authentication
guard let privateKey = try? String(contentsOfFile: privateKeyPath) else {
    print("Failed to load private key.")
    exit(1)
}

// Function to toggle the TV power state
func togglePower() {
    // Establish an ADB connection to the device
    let adbCommand = "adb connect \(fireTVIP):\(fireTVPort)"
    runCommand(adbCommand)

    // Send the power key event
    let powerCommand = "adb shell input keyevent 26"
    runCommand(powerCommand)
    
    // Disconnect ADB session
    let disconnectCommand = "adb disconnect \(fireTVIP):\(fireTVPort)"
    runCommand(disconnectCommand)
}

// Helper function to run command-line commands
func runCommand(_ command: String) {
    let task = Process()
    task.launchPath = "/bin/bash"
    task.arguments = ["-c", command]
    task.launch()
    task.waitUntilExit()
}

// Example usage
togglePower()
Thread.sleep(forTimeInterval: 5)  // Wait 5 seconds
togglePower()
