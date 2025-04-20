//
//  USBSerialScanner.swift
//  Robart
//
//  Created by Carsten Nichte on 15.04.25.
//

#if os(iOS)
import Foundation

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

    func scanSerialDevices() {
        // Keine USB-Serial-Unterstützung auf iOS
    }
    
    func connectToSelectedDevice() {
        // Keine USB-Serial-Unterstützung auf iOS
    }
}
#endif
