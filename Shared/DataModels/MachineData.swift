//
//  MachineData.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

// MachineData.swift
import Foundation

enum MachineType: String, Codable {
    case xyPlotter = ".xyPlotter"
    case omnidirektionalPlotter = ".omnidirektionalPlotter"
}

struct MachineData: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var description: String
    var typ: MachineType
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        typ: MachineType = .omnidirektionalPlotter
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.typ = typ
    }
}
