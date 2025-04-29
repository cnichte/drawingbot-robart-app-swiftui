//
//  SectionHeader.swift
//  Robart
//
//  Created by Carsten Nichte on 24.04.25.
//

import SwiftUI

struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.vertical, 8)
            .padding(.horizontal, 16) // Angepasstes Padding, um mit Form-Inhalt zu fluchten
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorHelper.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4)) // clipShape statt cornerRadius für konsistente Hintergrundform
    }
}
