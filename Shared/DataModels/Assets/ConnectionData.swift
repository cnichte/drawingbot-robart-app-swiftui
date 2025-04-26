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
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        typ: ConnectionType = .bluetooth
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.typ = typ
    }
    
    static func == (lhs: ConnectionData, rhs: ConnectionData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
