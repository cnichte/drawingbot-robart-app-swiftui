//
//  PaperFormatData.swift
//  Robart
//
//  Created by Carsten Nichte on 24.04.25.
//

// PaperFormatData.swift
import Foundation
/*
 Die Formate der A-Reihe sind die Grundlage aller weiteren Papiernormen. Man spricht dabei auch von den beschnittenen Formaten:
 DIN A0: 841 x 1189 mm
 DIN A1: 594 x 841 mm
 DIN A2: 420 x 594 mm
 DIN A3: 297 x 420 mm
 DIN A4: 210 x 297 mm
 DIN A5: 148 x 210 mm
 DIN A6: 105 x 148 mm
 DIN A7: 74 x 105 mm
 DIN A8: 52 x 74 mm
 DIN A9: 37 x 52 mm
 DIN A10: 26 x 37 mm
 
 Die B-Reihe enthält die Formate für die sogenannten unbeschnittenen Druckbogenformate; sie haben die größten Abmessungen:
 DIN B0: 1000 x 1414 mm
 DIN B1:707 x 1000 mm
 DIN B2: 500 x 707 mm
 DIN B3: 353 x 500 mm
 DIN B4: 250 x 353 mm
 DIN B5: 176 x 250 mm
 DIN B6: 125 x 176 mm
 DIN B7: 88 x 125 mm
 DIN B8: 62 x 88 mm
 DIN B9: 44 x 62 mm
 DIN B10: 31 x 44 mm
 */

// PaperFormatData.swift
import Foundation

struct PaperFormatData: Codable, Equatable, Identifiable, Hashable, ManageableItem  {
    
    var id: UUID
    var name: String
    var description: String
    var width:Double
    var height:Double
    var aspectRatio:AspectRatioData
    var unit:UnitsData
    
    static var `default`: PaperFormatData {
        PaperFormatData(id: UUID.force("7e3eb341-cee9-4da6-8acb-677d5cb19e13"), name: "DIN A4", width: 210, height: 297, aspectRatio: .default , unit: .default)
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        width:Double = 0,
        height:Double = 0,
        aspectRatio:AspectRatioData = .default,
        unit:UnitsData = .default
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.width = width
        self.height = height
        self.aspectRatio = aspectRatio
        self.unit = unit
    }
    
    static func == (lhs: PaperFormatData, rhs: PaperFormatData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
