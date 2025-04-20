//
//  SettingsData.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 14.04.25.
//

// SettingsData.swift
import Foundation

struct SettingsData: Codable {
    var name: String
    var description: String

    init(
        name: String,
        description: String = "",
    ) {
        self.name = name
        self.description = description
    }
}
