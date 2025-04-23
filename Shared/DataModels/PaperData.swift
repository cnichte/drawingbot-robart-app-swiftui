//
//  PaperData.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

import Foundation

struct PaperData: Codable, Equatable, Identifiable, Hashable, ManageableItem  {
    
    var id: UUID
    var name: String
    var description: String

    // Computed Property
    var displayName: String {
        name
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.description = description
    }
    
    static func == (lhs: PaperData, rhs: PaperData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
