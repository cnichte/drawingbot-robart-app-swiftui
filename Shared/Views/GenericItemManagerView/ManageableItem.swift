//
//  ManageableItem.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

import Foundation

// ManageableItem.swift
// #if os(macOS)
protocol ManageableItem: Identifiable, Codable, Equatable where ID == UUID {
    var displayName: String { get }
}
// #endif
