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
    
    // NEU für USB
    var usbVendorID: Int?
    var usbProductID: Int?
    var usbPath: String?

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        typ: ConnectionType = .bluetooth,
        usbVendorID: Int? = nil,
        usbProductID: Int? = nil,
        usbPath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.typ = typ
        self.usbVendorID = usbVendorID
        self.usbProductID = usbProductID
        self.usbPath = usbPath
    }

    static func == (lhs: ConnectionData, rhs: ConnectionData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
