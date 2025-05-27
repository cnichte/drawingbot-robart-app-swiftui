//
//  UnitsData.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// UnitsData.swift
import Foundation

struct UnitsData: Codable, Equatable, Identifiable, Hashable, ManageableItem, Defaultable  {
    
    var id: UUID
    var name: String
    var factor: Double
    
    static var `default`: UnitsData {
        UnitsData(id: UUID.force("5f6bbf82-57cc-435d-8644-655481cd556b"), name: "mm", factor: 0.001 )
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        factor: Double = 1.0
    ) {
        self.id = id
        self.name = name
        self.factor = factor
    }
    
    static func == (lhs: UnitsData, rhs: UnitsData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
