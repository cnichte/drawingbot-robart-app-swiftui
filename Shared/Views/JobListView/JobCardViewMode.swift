//
//  JobCardViewMode.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// JobCardViewMode.swift
enum JobCardViewMode: String, CaseIterable, Identifiable {
    case list
    case grid

    var id: String { rawValue }

    var label: String {
        switch self {
        case .list: return "Liste"
        case .grid: return "Gitter"
        }
    }

    var systemImage: String {
        switch self {
        case .list: return "list.bullet"
        case .grid: return "square.grid.2x2"
        }
    }
}
