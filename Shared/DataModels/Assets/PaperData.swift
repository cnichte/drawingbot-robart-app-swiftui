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
    
    static var `default`: PaperData {
        PaperData(id: UUID.force("4d024e70-2825-4d95-8039-c29685063040"), name: "Kein Papier")
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        weight: String = "100",
        color: String = "weiß",
        hersteller: String = "unknown",
        shoplink: String = "",
        description: String = "",
        paperFormat: PaperFormat = .default
    ) {
        self.id = id
        self.name = name
        self.weight = "100"
        self.color = "weiß"
        self.hersteller = "unknown"
        self.shoplink = ""
        self.description = description
        self.paperFormat = paperFormat
        
    }
    
    static func == (lhs: PaperData, rhs: PaperData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
