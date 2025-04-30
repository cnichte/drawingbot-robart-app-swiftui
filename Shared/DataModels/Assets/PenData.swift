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
    var farben: [String]
    var farbe: String // selected color?
    var variante: [PenVariante]

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        hersteller: String = "",
        shoplink: String = "",
        farben: [String] = [],
        farbe: String = "",
        variante: [PenVariante] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.hersteller = hersteller
        self.shoplink = shoplink
        self.farben = farben
        self.farbe = farbe
        self.variante = variante
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

struct PenVariante: Codable, Equatable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var spitze: Size
    var spitzeUnit: UnitInfo
    var reichweite: Double
    var reichweiteUnit: UnitInfo
}

struct Size: Codable, Equatable, Hashable {
    var x: Double
    var y: Double
}

struct UnitInfo: Codable, Equatable, Hashable, Identifiable {
    var id: UUID
    var name: String
}
