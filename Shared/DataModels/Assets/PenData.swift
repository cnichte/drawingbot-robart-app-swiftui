//
//  PenData.swift
//  Robart
//
//  Created by Carsten Nichte on 15.04.25.
//

// PenData.swift
import Foundation

struct PenData: Codable, Equatable, Identifiable, Hashable, ManageableItem, Defaultable {
    var id: UUID
    var name: String
    var description: String
    var hersteller: String
    var shoplink: String
    var farben: [PenColor]
    var varianten: [PenVariante]
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        hersteller: String = "",
        shoplink: String = "",
        farben: [PenColor] = [],
        varianten: [PenVariante] = [],
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.hersteller = hersteller
        self.shoplink = shoplink
        self.farben = farben
        self.varianten = varianten
    }

    static var `default`: PenData {
        PenData(id: UUID.force("a21f8095-bd2c-4c68-9714-f5e1d2b70687"), name: "Kein Stift")
    }
    
    static func == (lhs: PenData, rhs: PenData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct PenColor: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var wert: String
}

struct PenVariante: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var name: String
    var spitzeSize: Size
    var spitzeUnit: UnitsData
    var reichweite: Double
    var reichweiteUnit: UnitsData
}

struct Size: Codable, Equatable, Hashable {
    var x: Double
    var y: Double
}
