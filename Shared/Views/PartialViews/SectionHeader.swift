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
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            // .background(Color.accentColor.opacity(0.1))
            .background(ColorHelper.backgroundColor)
            .cornerRadius(4)
    }
}
