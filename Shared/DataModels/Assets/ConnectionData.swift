//
//  ConnectionsData.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

// ConnectionsData.swift
import Foundation

enum ConnectionType: String, Codable {
    case usb = ".usb"
    case bluetooth = ".bluetooth"
}

struct ConnectionData: Codable, Equatable, Identifiable, Hashable, ManageableItem {
    var id: UUID
    var name: String
    var description: String
    var typ: ConnectionType
    
    // --- USB ---
    var usbVendorID: Int?
    var usbProductID: Int?
    var usbPath: String?

    // --- Bluetooth ---
    var btPeripheralUUID: UUID?  // eindeutige Geräte-UUID (CoreBluetooth)
    var btServiceUUID: String?   // optional, für FFE0/FFE1

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

    // Implementierung von Equatable
    static func == (lhs: ConnectionData, rhs: ConnectionData) -> Bool {
        return lhs.id == rhs.id
    }

    // Implementierung von Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Definiere CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case typ
        case usbVendorID
        case usbProductID
        case usbPath
        case btPeripheralUUID
        case btServiceUUID
    }

    // Custom Encoding, um nil-Werte zu behandeln
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(typ, forKey: .typ)

        // Explizit auch nil-Werte für optionale Felder im JSON speichern
        try container.encodeIfPresent(usbVendorID, forKey: .usbVendorID)
        try container.encodeIfPresent(usbProductID, forKey: .usbProductID)
        try container.encodeIfPresent(usbPath, forKey: .usbPath)
        try container.encodeIfPresent(btPeripheralUUID, forKey: .btPeripheralUUID)
        try container.encodeIfPresent(btServiceUUID, forKey: .btServiceUUID)
    }

    // Custom Decoding, um nil-Werte zu behandeln
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        typ = try container.decode(ConnectionType.self, forKey: .typ)

        usbVendorID = try container.decodeIfPresent(Int.self, forKey: .usbVendorID)
        usbProductID = try container.decodeIfPresent(Int.self, forKey: .usbProductID)
        usbPath = try container.decodeIfPresent(String.self, forKey: .usbPath)
        btPeripheralUUID = try container.decodeIfPresent(UUID.self, forKey: .btPeripheralUUID)
        btServiceUUID = try container.decodeIfPresent(String.self, forKey: .btServiceUUID)
    }
}
