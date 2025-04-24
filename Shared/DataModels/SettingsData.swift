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
    var storageType: StorageType
    var preferredStorage: StorageType
    
    init(
        id: UUID = UUID(),
        storageType: StorageType = .local,
        preferredStorage: StorageType = .local
    ) {
        self.id = id
        self.storageType = storageType
        self.preferredStorage = preferredStorage
    }
    
    // Equatable: Compare all properties for equality
    static func == (lhs: SettingsData, rhs: SettingsData) -> Bool {
        return lhs.id == rhs.id &&
               lhs.storageType == rhs.storageType &&
               lhs.preferredStorage == rhs.preferredStorage
    }
    
    // Hashable: Include all properties in hash
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(storageType)
        hasher.combine(preferredStorage)
    }
}
