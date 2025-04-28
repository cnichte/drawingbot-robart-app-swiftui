//
//  USBSerialScanner.swift
//  Robart
//
//  Created by Carsten Nichte on 15.04.25.
//  Copyright (C) 2025
//  https://carsten-nichte.de/docs/drawingbot/
//  This file is part of Robart.
//  Licensed under the GNU General Public License v3.0. See LICENSE for details.
//

#if os(iOS)
import Foundation
import ExternalAccessory

struct USBSerialDevice: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let vendorID: Int?
    let productID: Int?
    let description: String
    
    var name: String {
        "\(description) (\(path))"
    }
}

class USBSerialScanner: ObservableObject {
    @Published var devices: [USBSerialDevice] = []
    @Published var selectedDevice: USBSerialDevice?

    func scanSerialDevices() {
        // Keine USB-Serial-Unterstützung auf iOS
        
    }
    
    func connectToSelectedDevice() {
        // Keine USB-Serial-Unterstützung auf iOS
/*
        let accessoryManager = EAAccessoryManager.shared()
        accessoryManager.registerForLocalNotifications()

        NotificationCenter.default.addObserver(forName: .EAAccessoryDidConnect, object: nil, queue: .main) { notification in
            if let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory {
                appLog("Connected accessory: \(accessory.name)")
                // Open a session
                let session = EASession(accessory: accessory, forProtocol: "com.yourcompany.protocolname")
                if let inputStream = session?.inputStream, let outputStream = session?.outputStream {
                    inputStream.delegate = self
                    outputStream.delegate = self
                    inputStream.schedule(in: .main, forMode: .default)
                    outputStream.schedule(in: .main, forMode: .default)
                    inputStream.open()
                    outputStream.open()
                }
            }
        }

        // Show accessory picker if needed
        accessoryManager.showBluetoothAccessoryPicker(withNameFilter: nil) { error in
            if let error = error {
                appLog("Error picking accessory: \(error)")
            }
        }
 */
    }
}


/*
 extension YourViewController: StreamDelegate {
     func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
         switch eventCode {
         case .hasBytesAvailable:
             if let inputStream = aStream as? InputStream {
                 var buffer = [UInt8](repeating: 0, count: 1024)
                 let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
                 if bytesRead > 0 {
                     let data = Data(buffer.prefix(bytesRead))
                     appLog("Received data: \(data)")
                 }
             }
         case .errorOccurred:
             appLog("Stream error: \(aStream.streamError?.localizedDescription ?? "Unknown")")
         default:
             break
         }
     }
 }
 */
#endif
