//
//  AspectRatioData.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// AspectRatioData.swift
import Foundation

struct AspectRatioData: Codable, Equatable, Identifiable, Hashable, ManageableItem  {
    
    var id: UUID
    var name: String
    var factor:Double
    
    static var `default`: AspectRatioData {
        AspectRatioData(id: UUID.force("4b34dc07-a722-4a40-8bbf-8503739db801"), name: "From Paper", factor: 1.0)
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        factor:Double = 1.0,
    ) {
        self.id = id
        self.name = name
        self.factor = factor
    }
    
    static func == (lhs: AspectRatioData, rhs: AspectRatioData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
