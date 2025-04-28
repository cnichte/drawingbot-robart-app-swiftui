//
//  SignatureSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// SignatureSectionView.swift
import SwiftUI

struct SignatureSectionView: View {
    var body: some View {
        CollapsibleSection(title: "Signatur", systemImage: "signature", toolbar: { EmptyView() }) {
            Text("Signatur-Einstellungen folgen...")
                .foregroundColor(.secondary)
        }
    }
}
