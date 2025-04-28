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

// USBSerialScanner.swift
#if os(macOS)
import Foundation
import ORSSerial
import IOKit

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
    
    var currentPort: ORSSerialPort?
    
    func scanSerialDevices() {
        let ports = ORSSerialPortManager.shared().availablePorts
        let list = ports.compactMap { port -> USBSerialDevice? in
            let (vendor, product) = Self.getVendorProductID(for: port.path)
            return USBSerialDevice(
                path: port.path,
                vendorID: vendor,
                productID: product,
                description: port.name
            )
        }
        
        DispatchQueue.main.async {
            self.devices = list
            self.tryAutoConnect()
        }
    }
    
    func tryAutoConnect() {
        for device in devices {
            if let match = AssetStores.shared.connectionsStore.items.first(where: {
                $0.typ == .usb &&
                $0.usbVendorID == device.vendorID &&
                $0.usbProductID == device.productID
            }) {
                connect(to: device)
                ConnectionManager.shared.connect(connection: match)
                return
            }
        }
    }
    
    func connectToSelectedDevice() {
        guard let device = selectedDevice else { return }
        connect(to: device)
    }
    
    public func connect(to device: USBSerialDevice) {
        let port = ORSSerialPort(path: device.path)
        port?.baudRate = 9600
        port?.open()
        self.currentPort = port
    }
    
    static func getVendorProductID(for bsdPath: String) -> (Int?, Int?) {
        let kIOSerialBSDDeviceKey = "IODialinDevice" as CFString
        
        guard let matching = IOServiceMatching("IOSerialBSDClient") else { return (nil, nil) }
        guard let cfPath = bsdPath.cString(using: .utf8).flatMap({
            CFStringCreateWithCString(kCFAllocatorDefault, $0, CFStringBuiltInEncodings.UTF8.rawValue)
        }) else { return (nil, nil) }
        
        CFDictionarySetValue(
            matching,
            Unmanaged.passUnretained(kIOSerialBSDDeviceKey).toOpaque(),
            Unmanaged.passUnretained(cfPath).toOpaque()
        )
        
        var service: io_iterator_t = 0
        IOServiceGetMatchingServices(kIOMainPortDefault, matching, &service)
        let device = IOIteratorNext(service)
        
        var vendorID: Int32 = 0
        var productID: Int32 = 0
        
        if device != 0 {
            if let v = IORegistryEntryCreateCFProperty(device, "idVendor" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int32 {
                vendorID = v
            }
            if let p = IORegistryEntryCreateCFProperty(device, "idProduct" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int32 {
                productID = p
            }
            IOObjectRelease(device)
        }
        IOObjectRelease(service)
        
        return (Int(vendorID), Int(productID))
    }
}
#endif
