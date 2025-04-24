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
    }
}
#endif
