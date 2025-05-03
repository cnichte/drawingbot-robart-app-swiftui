//
//  ConnectionsData.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//
// TODO: doAutoConnectWhenAvailible:Bool

// ConnectionsData.swift
import Foundation

enum ConnectionType: String, Codable {
    case usb = ".usb"
    case bluetooth = ".bluetooth"
}

struct ConnectionData: Codable, Equatable, Identifiable, Hashable, ManageableItem, Defaultable {
    
    // Basis
    var id: UUID            = UUID()
    var name: String        = ""          // Vom Benutzer frei wählbar
    var description: String = ""
    var typ: ConnectionType = .bluetooth

    // --- USB Geräte‐Eigenschaften ---
    var usbVendorID:  Int?
    var usbProductID: Int?
    var usbPath:      String?
    var usbName:      String?   // z. B. „debug‑console (cu.debug…)“
    var usbDesc:      String?   // Hersteller‑/Produkttext falls gewünscht

    // --- Bluetooth Geräte‐Eigenschaften ---
    var btPeripheralUUID: UUID?
    var btPeripheralName: String?
    var btServiceUUID:    String?

    // Initialisierer für ConnectionData
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        typ: ConnectionType = .bluetooth,
        usbVendorID: Int? = nil,
        usbProductID: Int? = nil,
        usbPath: String? = nil,
        btPeripheralUUID: UUID? = nil,
        btServiceUUID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.typ = typ
        self.usbVendorID = usbVendorID
        self.usbProductID = usbProductID
        self.usbPath = usbPath
        self.btPeripheralUUID = btPeripheralUUID
        self.btServiceUUID = btServiceUUID
    }

    static var `default`: ConnectionData {
        ConnectionData(
            id: UUID.force("d56e6776-8e43-4b50-b5a1-1d20a5d414d0"),
            name: "Ohne Verbindung",
            description: ""
        )
    }
    
    // Implementierung von Equatable
    static func == (lhs: ConnectionData, rhs: ConnectionData) -> Bool {
        return lhs.id == rhs.id
    }

    // Implementierung von Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
