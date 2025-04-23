//
//  SettingsData.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 14.04.25.
//

// SettingsData.swift
import Foundation

struct SettingsData: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var description: String

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
    ) {
        self.id = id
        self.name = name
        self.description = description
    }
    
    static func == (lhs: SettingsData, rhs: SettingsData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
