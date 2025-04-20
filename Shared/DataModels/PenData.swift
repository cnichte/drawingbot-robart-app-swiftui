//
//  PenData.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

import Foundation

struct PenData: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var description: String

    init(
        id: UUID = UUID(),
        name: String,
        description: String = ""
    ) {
        self.id = id
        self.name = name
        self.description = description
    }
}
