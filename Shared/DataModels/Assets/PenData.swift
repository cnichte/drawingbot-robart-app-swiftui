//
//  PenData.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

// PenData.swift
import Foundation

struct PenData: Codable, Equatable, Identifiable, Hashable, ManageableItem {
    
    var id: UUID
    var name: String
    var description: String
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.description = description
    }
    
    static func == (lhs: PenData, rhs: PenData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
