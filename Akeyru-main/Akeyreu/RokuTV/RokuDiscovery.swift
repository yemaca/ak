//
//  RokuDiscovery.swift
//  Akeyreu
//
//  Created by Asher Amey on 9/18/24.
//

import Foundation
import Network

class RokuDiscovery {
    static let shared = RokuDiscovery()
    private let multicastAddress = "239.255.255.250"
    private let port: NWEndpoint.Port = 1900
    private let searchTarget = "roku:ecp"
    
    func discover(completion: @escaping ([RokuTVControl]) -> Void) {
        var discoveredDevices: [RokuTVControl] = []
        
        let message = """
        M-SEARCH * HTTP/1.1\r
        HOST: 239.255.255.250:1900\r
        MAN: "ssdp:discover"\r
        MX: 3\r
        ST: \(searchTarget)\r
        \r
        """
        
        print("Sending SSDP request")
        
        guard let messageData = message.data(using: .utf8) else {
            print("Failed to create message data")
            completion([])
            return
        }
        
        let params = NWParameters.udp
        let connection = NWConnection(host: NWEndpoint.Host(multicastAddress), port: port, using: params)
        
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("Connection ready. Sending SSDP message...")
                connection.send(content: messageData, completion: .contentProcessed { sendError in
                    if let error = sendError {
                        print("Send error: \(error)")
                        connection.cancel()
                        completion(discoveredDevices)
                        return
                    }
                    self.receiveResponses(on: connection) { devices in
                        discoveredDevices.append(contentsOf: devices)
                        print("Discovered devices: \(discoveredDevices)")
                        completion(discoveredDevices)
                    }
                })
            case .failed(let error):
                print("Connection failed: \(error)")
                connection.cancel()
                completion(discoveredDevices)
            default:
                break
            }
        }
        
        connection.start(queue: .global())
    }


    
    private func receiveResponses(on connection: NWConnection, completion: @escaping ([RokuTVControl]) -> Void) {
        var discoveredDevices: [RokuTVControl] = []
        
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65535) { data, _, isComplete, error in
            if let data = data, let response = String(data: data, encoding: .utf8) {
                print("Received SSDP response: \(response)")  // Debugging log
                
                if let device = self.parseResponse(response) {
                    print("Parsed device: \(device.name) at \(device.ip)")  // Debugging log
                    if !discoveredDevices.contains(where: { $0.ip == device.ip }) {
                        discoveredDevices.append(device)
                    }
                }
            } else {
                print("No data or error: \(error?.localizedDescription ?? "None")")  // Debugging log
            }
            
            if isComplete || error != nil {
                connection.cancel()
                print("Discovery complete with devices: \(discoveredDevices)")  // Debugging log
                completion(discoveredDevices)
            } else {
                self.receiveResponses(on: connection, completion: completion)
            }
        }
    }
    
    private func parseResponse(_ response: String) -> RokuTVControl? {
        // Parse LOCATION header to get device info
        let lines = response.components(separatedBy: "\r\n")
        var locationURL: String?
        
        for line in lines {
            if line.lowercased().starts(with: "location:") {
                locationURL = line.dropFirst("location:".count).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        guard let location = locationURL, let url = URL(string: location) else {
            return nil
        }
        
        // Fetch device description XML
        if let data = try? Data(contentsOf: url), let xml = String(data: data, encoding: .utf8) {
            // Simple XML parsing to extract friendlyName and IP
            let name = self.extractXMLValue(xml: xml, tag: "friendlyName") ?? "Unknown"
            let ip = url.host ?? "Unknown"
            return RokuTVControl(name: name, ip: ip)
        }
        
        return nil
    }
    
    private func extractXMLValue(xml: String, tag: String) -> String? {
        guard let startRange = xml.range(of: "<\(tag)>"),
              let endRange = xml.range(of: "</\(tag)>", range: startRange.upperBound..<xml.endIndex) else {
            return nil
        }
        return String(xml[startRange.upperBound..<endRange.lowerBound])
    }
}


//import Foundation
//import Network
//
//func discoverRokuDevices(completion: @escaping ([RokuTVControl]) -> Void) {
//    print("Starting Roku device discovery...")  // Logging
//
//    let SSDP_GROUP = "239.255.255.250"
//    let SSDP_PORT: UInt16 = 1900
//
//    let MSEARCH_MSG = """
//    M-SEARCH * HTTP/1.1\r
//    HOST: \(SSDP_GROUP):\(SSDP_PORT)\r
//    MAN: "ssdp:discover"\r
//    MX: 1\r
//    ST: roku:ecp\r
//    \r
//    """
//
//    var rokuDevices = Set<String>()
//    let queue = DispatchQueue(label: "SSDPQueue")
//    let group = DispatchGroup()
//    group.enter()
//
//    let parameters = NWParameters.udp
//    parameters.allowLocalEndpointReuse = true
//
//    let multicastHost = NWEndpoint.Host(SSDP_GROUP)
//    let port = NWEndpoint.Port(rawValue: SSDP_PORT)!
//
//    let connection = NWConnection(host: multicastHost, port: port, using: parameters)
//
//    connection.stateUpdateHandler = { newState in
//        switch newState {
//        case .ready:
//            print("Connection is ready. Sending discovery message...")
//            let data = MSEARCH_MSG.data(using: .utf8)!
//            connection.send(content: data, completion: .contentProcessed { error in
//                if let error = error {
//                    print("Error sending data: \(error)")
//                    group.leave()
//                } else {
//                    receiveResponses(connection: connection, devices: rokuDevices, group: group) { discoveredDevices in
//                        rokuDevices = discoveredDevices
//                    }
//                }
//            })
//        case .failed(let error):
//            print("Connection failed: \(error)")
//            group.leave()
//        default:
//            break
//        }
//    }
//
//    connection.start(queue: queue)
//
//    group.notify(queue: .main) {
//        connection.cancel()
//        let rokuTVControls = rokuDevices.map { ip in
//            RokuTVControl(name: "Roku Device \(ip)", ip: ip)
//        }
//        completion(rokuTVControls)
//    }
//}
//
//// Function to receive responses from devices
//func receiveResponses(connection: NWConnection, devices: Set<String>, group: DispatchGroup, completion: @escaping (Set<String>) -> Void) {
//    var localDevices = devices
//
//    connection.receiveMessage { (data, context, isComplete, error) in
//        if let error = error {
//            print("Error receiving data: \(error)")
//            group.leave()
//            return
//        }
//        if let data = data, let response = String(data: data, encoding: .utf8) {
//            print("Received response: \(response)")  // Logging response
//            if response.contains("roku:ecp") {
//                if let senderIP = extractIPAddress(from: response) {
//                    localDevices.insert(senderIP)
//                    print("Found Roku device at IP: \(senderIP)")  // Logging found device
//                }
//            }
//        }
//
//        // Continue receiving
//        receiveResponses(connection: connection, devices: localDevices, group: group, completion: completion)
//    }
//
//    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
//        group.leave()
//        completion(localDevices)
//    }
//}
//
//// Helper function to extract IP address from the response
//func extractIPAddress(from response: String) -> String? {
//    if let locationLine = response.components(separatedBy: "\r\n").first(where: { $0.hasPrefix("LOCATION:") || $0.hasPrefix("Location:") }),
//       let url = locationLine.components(separatedBy: " ").last,
//       let host = URL(string: url)?.host {
//        return host
//    }
//    return nil
//}


//// Function to discover Roku devices on the local network and return RokuTVControl objects
//import Foundation
//import Network
//
//// Function to discover Roku devices on the local network
//func discoverRokuDevices(completion: @escaping ([RokuTVControl]) -> Void) {
//    let SSDP_GROUP = "239.255.255.250"
//    let SSDP_PORT: UInt16 = 1900
//
//    let MSEARCH_MSG = """
//    M-SEARCH * HTTP/1.1\r
//    HOST: \(SSDP_GROUP):\(SSDP_PORT)\r
//    MAN: "ssdp:discover"\r
//    MX: 1\r
//    ST: roku:ecp\r
//    \r
//    """
//
//    var rokuDevices = Set<String>()
//    let queue = DispatchQueue(label: "SSDPQueue")
//    let group = DispatchGroup()
//    group.enter()
//
//    // Create parameters for UDP connection
//    let parameters = NWParameters.udp
//    parameters.allowLocalEndpointReuse = true
//
//    // Create a multicast group endpoint
//    let multicastHost = NWEndpoint.Host(SSDP_GROUP)
//    let port = NWEndpoint.Port(rawValue: SSDP_PORT)!
//
//    // Create a UDP connection
//    let connection = NWConnection(host: multicastHost, port: port, using: parameters)
//
//    connection.stateUpdateHandler = { newState in
//        switch newState {
//        case .ready:
//            // Send the M-SEARCH message
//            let data = MSEARCH_MSG.data(using: .utf8)!
//            connection.send(content: data, completion: .contentProcessed { error in
//                if let error = error {
//                    print("Error sending data: \(error)")
//                    group.leave()
//                } else {
//                    // Start receiving responses
//                    receiveResponses(connection: connection, devices: rokuDevices, group: group) { discoveredDevices in
//                        rokuDevices = discoveredDevices  // Update the rokuDevices with the returned devices
//                    }
//                }
//            })
//        default:
//            break
//        }
//    }
//
//    connection.start(queue: queue)
//
//    // Wait for responses for a specified duration
//    group.notify(queue: .main) {
//        connection.cancel()
//
//        // Create RokuTVControl objects from the discovered IP addresses
//        let rokuTVControls = rokuDevices.map { ip in
//            RokuTVControl(name: "Roku Device \(ip)", ip: ip)
//        }
//
//        // Call the completion handler with the RokuTVControl objects
//        completion(rokuTVControls)
//    }
//}
//
//// Function to receive responses from devices
//func receiveResponses(connection: NWConnection, devices: Set<String>, group: DispatchGroup, completion: @escaping (Set<String>) -> Void) {
//    var localDevices = devices  // Create a local mutable copy
//
//    connection.receiveMessage { (data, context, isComplete, error) in
//        if let data = data, let response = String(data: data, encoding: .utf8) {
//            if response.contains("roku:ecp") {
//                // Extract the IP address from the response
//                if let senderIP = extractIPAddress(from: response) {
//                    localDevices.insert(senderIP)  // Modify the local copy
//                }
//            }
//        }
//
//        if let error = error {
//            print("Error receiving data: \(error)")
//            group.leave()
//        } else {
//            // Continue receiving responses
//            receiveResponses(connection: connection, devices: localDevices, group: group, completion: completion)
//        }
//    }
//
//    // Set a timeout for the discovery process
//    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
//        group.leave()
//        completion(localDevices)  // Use completion handler to return updated devices set
//    }
//}
//
//// Helper function to extract IP address from the response
//func extractIPAddress(from response: String) -> String? {
//    if let locationLine = response.components(separatedBy: "\r\n").first(where: { $0.hasPrefix("LOCATION:") || $0.hasPrefix("Location:") }),
//       let url = locationLine.components(separatedBy: " ").last,
//       let host = URL(string: url)?.host {
//        return host
//    }
//    return nil
//}


//class RokuDiscovery {
//    private let ssdpAddress = "239.255.255.250"
//    private let ssdpPort: UInt16 = 1900
//    private let searchTarget = "roku:ecp"
//    
//    // Discover Roku devices on the network
//    func discoverRokuDevices(completion: @escaping ([String]) -> Void) {
//        var discoveredRokuIPs: [String] = []
//        
//        let message = """
//        M-SEARCH * HTTP/1.1\r\n
//        HOST: \(ssdpAddress):\(ssdpPort)\r\n
//        MAN: "ssdp:discover"\r\n
//        MX: 1\r\n
//        ST: \(searchTarget)\r\n\r\n
//        """
//        
//        let data = message.data(using: .utf8)!
//        let group = DispatchGroup()
//        
//        let udpSocket = NWConnection(host: NWEndpoint.Host(ssdpAddress), port: NWEndpoint.Port(rawValue: ssdpPort)!, using: .udp)
//        udpSocket.stateUpdateHandler = { state in
//            switch state {
//            case .ready:
//                udpSocket.send(content: data, completion: .contentProcessed({ error in
//                    if let error = error {
//                        print("Error sending M-SEARCH: \(error)")
//                    } else {
//                        print("M-SEARCH sent successfully.")
//                    }
//                }))
//            default:
//                break
//            }
//        }
//        
//        udpSocket.receiveMessage { (content, context, isComplete, error) in
//            if let content = content, let response = String(data: content, encoding: .utf8) {
//                if response.contains(self.searchTarget), let ipRange = response.range(of: "http://") {
//                    let ip = response[ipRange.upperBound...].components(separatedBy: ":").first!
//                    discoveredRokuIPs.append(String(ip))
//                    print("Discovered Roku device at IP: \(ip)")
//                }
//            }
//            group.leave()
//        }
//        
//        group.enter()
//        udpSocket.start(queue: .main)
//        
//        group.notify(queue: .main) {
//            completion(discoveredRokuIPs)
//        }
//    }
//}
