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
import IOKit
import ORSSerial

struct USBSerialDevice: Identifiable, Hashable {
    let id = UUID()
    let path: String
    let vendorID: Int?
    let productID: Int?
    let description: String
    
    var displayName: String {
        "\(description) (\(path))"
    }
}

class USBSerialScanner: ObservableObject {
    @Published var devices: [USBSerialDevice] = []
    @Published var selectedDevice: USBSerialDevice?
    
    var currentPort: ORSSerialPort?
    
    func scanSerialDevices() {
        let manager = ORSSerialPortManager.shared()
        let ports = manager.availablePorts
        
        let deviceList = ports.compactMap { port -> USBSerialDevice? in
            guard let bsdPath = port.path as String? else { return nil }
            let (vendor, product) = Self.getVendorProductID(for: bsdPath)
            return USBSerialDevice(
                path: bsdPath,
                vendorID: vendor,
                productID: product,
                description: port.name
            )
        }
        
        DispatchQueue.main.async {
            self.devices = deviceList
        }
    }
    
    func connectToSelectedDevice() {
        guard let device = selectedDevice else { return }
        let port = ORSSerialPort(path: device.path)
        port?.baudRate = 9600
        port?.open()
        self.currentPort = port
    }
    
    static func getVendorProductID(for bsdPath: String) -> (Int?, Int?) {
        let kIOSerialBSDDeviceKey = "IODialinDevice" as CFString
        
        guard let matching = IOServiceMatching("IOSerialBSDClient") else { return (nil, nil) }
        guard let bsdPathCString = bsdPath.cString(using: .utf8) else { return (nil, nil) }
        guard let cfBsdPath = CFStringCreateWithCString(kCFAllocatorDefault, bsdPathCString, CFStringBuiltInEncodings.UTF8.rawValue) else { return (nil, nil) }
        
        CFDictionarySetValue(
            matching,
            Unmanaged.passUnretained(kIOSerialBSDDeviceKey).toOpaque(),
            Unmanaged.passUnretained(cfBsdPath).toOpaque()
        )
        
        var service: io_iterator_t = 0
        IOServiceGetMatchingServices(kIOMainPortDefault, matching, &service)
        let device = IOIteratorNext(service)
        
        var vendorID: Int32 = 0
        var productID: Int32 = 0
        
        if device != 0 {
            let vendorIDNum = IORegistryEntryCreateCFProperty(device, "idVendor" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
            let productIDNum = IORegistryEntryCreateCFProperty(device, "idProduct" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
            
            if let v = vendorIDNum as? Int32 { vendorID = v }
            if let p = productIDNum as? Int32 { productID = p }
            
            IOObjectRelease(device)
        }
        
        IOObjectRelease(service)
        return (Int(vendorID), Int(productID))
    }
}
#endif

