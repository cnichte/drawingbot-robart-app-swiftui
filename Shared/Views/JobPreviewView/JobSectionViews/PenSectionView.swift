//
//  PenSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// PenSectionView.swift
import SwiftUI

struct PenSectionView: View {
    var body: some View {
        CollapsibleSection(title: "Stift", systemImage: "pencil.tip") {
            Text("Stift-Einstellungen folgen...")
                .foregroundColor(.secondary)
        }
    }
}
