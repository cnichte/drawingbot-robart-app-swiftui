//
//  JobListViewMode.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// JobListViewMode.swift
enum JobListViewMode: String, CaseIterable, Identifiable {
    case list
    case grid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .list: return "List" // List
        case .grid: return "Grid" // Grid
        }
    }

    var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        }
    }
}
