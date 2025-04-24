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
    var storageType: StorageType = .local
    var preferredStorage: StorageType = .local
    
    init(
        id: UUID = UUID(),
    ) {
        self.id = id
    }
    
    static func == (lhs: SettingsData, rhs: SettingsData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
