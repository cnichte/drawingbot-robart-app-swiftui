//
//  PaperData.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

// PaperData.swift
import Foundation

struct PaperData: Codable, Equatable, Identifiable, Hashable, ManageableItem  {
    
    var id: UUID
    var name: String
    var weight:String
    var color:String
    var hersteller:String
    var shoplink: String
    var description: String
    
    var paperFormat: PaperFormat = .default

    init(
        id: UUID = UUID(),
        name: String,
        weight: String = "100",
        color: String = "weiß",
        hersteller: String = "unknown",
        shoplink: String = "",
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.weight = "100"
        self.color = "weiß"
        self.hersteller = "unknown"
        self.shoplink = ""
        self.description = description
        
    }
    
    static func == (lhs: PaperData, rhs: PaperData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
