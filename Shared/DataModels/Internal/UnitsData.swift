//
//  Units.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// Units.swift
import Foundation

struct UnitsData: Codable, Equatable, Identifiable, Hashable, ManageableItem, Defaultable  {
    
    var id: UUID
    var name: String
    
    static var `default`: UnitsData {
        UnitsData(id: UUID.force("5f6bbf82-57cc-435d-8644-655481cd556b"), name: "mm", )
    }
    
    init(
        id: UUID = UUID(),
        name: String,
    ) {
        self.id = id
        self.name = name
    }
    
    static func == (lhs: UnitsData, rhs: UnitsData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
