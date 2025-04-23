//
//  ManageableItem.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

// ManageableItem.swift
import Foundation

protocol ManageableItem: Identifiable, Codable, Equatable where ID == UUID {
    var displayName: String { get }
}
