//
//  DeviceControl.swift
//  Akeyreu
//
//  Created by Asher Amey on 8/12/24.
//

import SwiftUI

struct DeviceControlView: View {
    @State private var devices: [RokuTVControl] = []
    @State private var selectedDevices: [RokuTVControl] = []
    @State private var newDeviceIP = ""
    @State private var newDeviceName = ""

    var body: some View {
        VStack {
            TextField("Enter Roku Name", text: $newDeviceName)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Enter Roku IP", text: $newDeviceIP)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Add Roku Device") {
                let newDevice = RokuTVControl(name: newDeviceName, ip: newDeviceIP)
                devices.append(newDevice)
                newDeviceIP = ""
                newDeviceName = ""
            }
            .disabled(newDeviceName.isEmpty || newDeviceIP.isEmpty)
            .padding(.bottom, 10)
            
            Button("Discover Roku Devices") {
                RokuDiscovery.shared.discover { discoveredDevices in
                    DispatchQueue.main.async {
                        // Append only new devices to avoid duplicates
                        for device in discoveredDevices {
                            if !devices.contains(where: { $0.ip == device.ip }) {
                                devices.append(device)
                            }
                        }
                    }
                }
            }

            
            List(devices) { device in
                DeviceRow(deviceName: device.getName(), isSelected: selectedDevices.contains(device)) {
                    if let index = selectedDevices.firstIndex(of: device) {
                        selectedDevices.remove(at: index)
                    } else {
                        selectedDevices.append(device)
                    }
                }
            }
            .frame(height: min(CGFloat(devices.count) * 85, 300))
            .border(devices.isEmpty ? Color.clear : Color.gray, width: 1)

            Button("Toggle Power") {
                for device in selectedDevices {
                    device.powerOff { success in
                        print("Power toggled for device \(device.getName()): \(success ? "Success" : "Failure")")
                    }
                }
            }
            .padding(.top, 10)
        }
        .padding()
    }
}


//import SwiftUI
//
//struct DeviceControlView: View {
//    @State private var devices: [RokuTVControl] = []
//    @State private var selectedDevices: [RokuTVControl] = []
//    @State private var newDeviceIP = ""
//    @State private var newDeviceName = ""
//
//    var body: some View {
//        VStack {
//            TextField("Enter Roku Name", text: $newDeviceName)
//                .padding()
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//            TextField("Enter Roku IP", text: $newDeviceIP)
//                .padding()
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//
//            Button("Add Roku Device") {
//                let newDevice = RokuTVControl(name: newDeviceName, ip: newDeviceIP)
//                devices.append(newDevice)
//                newDeviceIP = ""
//                newDeviceName = ""
//            }
//            .disabled(newDeviceName.isEmpty || newDeviceIP.isEmpty)
//            
//            Button("Discover Roku Devices") {
//                discoverRokuDevices { discoveredDevices in
//                    devices.append(contentsOf: discoveredDevices)
//                }
//            }
//            .padding()
//
//            List(devices, id: \.identifier) { device in
//                DeviceRow(deviceName: device.getName(), isSelected: selectedDevices.contains(where: { $0.getName() == device.getName() })) {
//                    if let index = selectedDevices.firstIndex(where: { $0.getName() == device.getName() }) {
//                        selectedDevices.remove(at: index)
//                    } else {
//                        selectedDevices.append(device)
//                    }
//                }
//            }
//            .frame(height: min(CGFloat(devices.count) * 85, 300))
//            .border(devices.isEmpty ? Color.clear : Color.gray, width: 1)
//
//            Button("Toggle Power") {
//                for device in selectedDevices {
//                    device.powerOff { success in
//                        print("Power toggled for device \(device.getName()): \(success ? "Success" : "Failure")")
//                    }
//                }
//            }
//        }
//        .padding()
//    }
//}

/*
 below shit works for saving ip address in table
 */

//import SwiftUI
//
//struct DeviceControlView: View {
//    @State private var devices: [RokuTVControl] = []
//    @State private var selectedDevices: [RokuTVControl] = []
//    @State private var newDeviceIP = ""
//    @State private var newDeviceName = ""
//    
//    var body: some View {
//        NavigationView {
//            VStack { // Main vertical stack
//                // Input fields at the top
//                TextField("Enter Roku Name", text: $newDeviceName)
//                    .padding()
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                TextField("Enter Roku IP", text: $newDeviceIP)
//                    .padding()
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                
//                // Button to add new device
//                Button("Add Roku Device") {
//                    let newDevice = RokuTVControl(name: newDeviceName, ip: newDeviceIP)
//                    devices.append(newDevice)
//                    newDeviceIP = ""
//                    newDeviceName = ""
//                }
//                .disabled(newDeviceName.isEmpty || newDeviceIP.isEmpty)
//                .padding(.bottom, 10) // Add space after button
//                
//                // Scrollable device list with a border
//                ScrollView {
//                    VStack(spacing: 10) { // Use spacing for rows
//                        ForEach(devices, id: \.identifier) { device in
//                            DeviceRow(deviceName: device.getName(),
//                                      isSelected: selectedDevices.contains(where: { $0.getName() == device.getName() })) {
//                                if let index = selectedDevices.firstIndex(where: { $0.getName() == device.getName() }) {
//                                    selectedDevices.remove(at: index)
//                                } else {
//                                    selectedDevices.append(device)
//                                }
//                            }
//                                      .padding() // Add padding to each row
//                                      .background(Color.white) // Background color for rows
//                                      .cornerRadius(5) // Rounded corners for each row
//                                      .shadow(color: Color.gray.opacity(0.2), radius: 2) // Optional shadow for visual effect
//                        }
//                    }
//                    .padding() // Add padding inside ScrollView
//                }
//                .background(RoundedRectangle(cornerRadius: 10) // Background for the border
//                    .stroke(devices.isEmpty ? Color.clear : Color.gray, lineWidth: 2)) // Set border color and width
//                .frame(height: min(CGFloat(devices.count) * 75, 250)) // Set a max height for the ScrollView area
//                
//                // Button to toggle power
//                Button("Toggle Power") {
//                    for device in selectedDevices {
//                        device.powerOff { success in
//                            print("Power toggled for device \(device.getName()): \(success ? "Success" : "Failure")")
//                        }
//                    }
//                }
//                .padding(.top, 10) // Optional: add padding for better layout
//                
//                NavigationLink(destination: FindRokuIPView()) {
//                    Text("How to Find Your Roku IP Address")
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                }
//                .padding(.top)
//            }
//            .padding() // Padding for the entire view
//            .navigationTitle("Roku Device Control") // Optional: title for navigation
//            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // Ensures top alignment
//        }
//    }
//}
//
struct DeviceRow: View {
    let deviceName: String
    let isSelected: Bool
    let toggleSelection: () -> Void
    
    var body: some View {
        HStack {
            Text(deviceName)
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleSelection()
        }
    }
}

struct DeviceControl_Previews: PreviewProvider {
    static var previews: some View {
        DeviceControlView()
    }
}
