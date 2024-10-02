//
//  RokuTVControl.swift
//  Akeyreu
//
//  Created by Asher Amey on 8/21/24.
//

import Foundation

struct RokuTVControl: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let ip: String

    func getName() -> String {
        return name
    }

    // Placeholder for powerOff functionality
    func powerOff(completion: @escaping (Bool) -> Void) {
        // Implement power off logic here, possibly using Roku's ECP API
        completion(true)
    }
}

//import Foundation

//class RokuTVControl {
//    private let ip: String
//    private let name: String
//    private let port: Int = 8060
//    
//    init(name: String, ip: String) {
//        self.name = name
//        self.ip = ip
//    }
//    
//    private func sendCommand(_ command: String, completion: @escaping (Bool) -> Void) {
//        guard let url = URL(string: "http://\(ip):\(port)/\(command)") else {
//            completion(false)
//            return
//        }
//        
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                print("Failed to send command: \(command), error: \(error)")
//                completion(false)
//                return
//            }
//            
//            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
//                print("Command \(command) sent successfully.")
//                completion(true)
//            } else {
//                print("Failed to send command: \(command)")
//                completion(false)
//            }
//        }
//        task.resume()
//    }
//    
//    func powerOn(completion: @escaping (Bool) -> Void) {
//        sendCommand("keypress/PowerOn", completion: completion)
//    }
//    
//    func powerOff(completion: @escaping (Bool) -> Void) {
//        sendCommand("keypress/PowerOff", completion: completion)
//    }
//    
//    func volumeUp(completion: @escaping (Bool) -> Void) {
//        sendCommand("keypress/VolumeUp", completion: completion)
//    }
//    
//    func volumeDown(completion: @escaping (Bool) -> Void) {
//        sendCommand("keypress/VolumeDown", completion: completion)
//    }
//    
//    func home(completion: @escaping (Bool) -> Void) {
//        sendCommand("keypress/Home", completion: completion)
//    }
//    
//    func launchApp(appID: String, completion: @escaping (Bool) -> Void) {
//        sendCommand("launch/\(appID)", completion: completion)
//    }
//    
//    func getName() -> String {
//        return name
//    }
//    
//    func getIP() -> String {
//        return ip
//    }
//    
//    var identifier: String {
//        return "\(name)-\(ip)"
//    }
//}
