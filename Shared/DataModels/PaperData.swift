//
//  PaperData.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

import Foundation

struct PaperData: Codable, Equatable, Identifiable, ManageableItem  {
    
    var id: UUID
    var name: String
    var description: String

    var displayName: String
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.displayName = name
    }
}
