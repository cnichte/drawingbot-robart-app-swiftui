//
//  ManageableItem.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//
#if os(macOS)
protocol ManageableItem: Identifiable, Codable, Equatable {
    var displayName: String { get }
}
#endif
