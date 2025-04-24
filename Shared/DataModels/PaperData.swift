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
    
    // var paperFormat: PaperFormat
    var width:Double = 210
    var height:Double = 297

    init(
        id: UUID = UUID(),
        name: String,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.width = 210
        self.height = 297
        // self.paperFormat = nil
    }
    
    static func == (lhs: PaperData, rhs: PaperData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
