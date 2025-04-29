//
//  SignatureData.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// SignatureData.swift
import Foundation

enum SignatureLocation: String, Codable, CaseIterable {
    case bottomLeft = ".bottomLeft"
    case bottomCenter = ".bottomCenter"
    case bottomRight = ".bottomRight"
    case topLeft = ".topLeft"
    case topCenter = ".topCenter"
    case topRight = ".topRight"
    static var allCases: [SignatureLocation] {
        return [.bottomLeft, .bottomCenter, .bottomRight, .topLeft, .topCenter, .topRight]
    }
}

struct SignatureData: Codable, Equatable, Identifiable, Hashable, ManageableItem, Defaultable {
    
    var id: UUID
    var name: String
    var description: String
    var svgFilePath: String
    var signatureLocation: SignatureLocation
    var abstandHorizontal: Double
    var abstandVertical: Double
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        svgFilePath: String = "",
        signatureLocation: SignatureLocation = .bottomRight,
        abstandHorizontal: Double = 0.0,
        abstandVertical: Double = 0.0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.svgFilePath = svgFilePath
        self.signatureLocation = signatureLocation
        self.abstandHorizontal = abstandHorizontal
        self.abstandVertical = abstandVertical
    }
    
    static var `default`: SignatureData {
        SignatureData(
            id: UUID.force("4be2dd2e-9de1-4e8b-9f33-a9c9696f85f4"),
            name: "Ohne Signatur",
            description: ""
        )
    }
    
    static func == (lhs: SignatureData, rhs: SignatureData) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
