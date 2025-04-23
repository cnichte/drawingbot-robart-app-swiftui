//
//  ManageableItem.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

// ManageableItem.swift
// #if os(macOS)
protocol ManageableItem: Identifiable, Codable, Equatable {
    var displayName: String { get }
}
// #endif
