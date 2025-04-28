//
//  Menubar.swift
//  Robart
//
//  Created by Carsten Nichte on 29.04.25.
//

// CollapsibleSection.swift
import SwiftUI

struct Menubar<Toolbar: View>: View {
    let title: String
    let systemImage: String
    let toolbar: Toolbar

    init(
        title: String,
        systemImage: String,
        @ViewBuilder toolbar: () -> Toolbar = { EmptyView() },
    ) {
        self.title = title
        self.systemImage = systemImage
        self.toolbar = toolbar()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    HStack {
                        Image(systemName: systemImage)
                        Text(title)
                            .font(.headline)
                            .lineLimit(1)
                        Spacer()
                    }
                    // Toolbar direkt daneben
                    toolbar
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(ColorHelper.backgroundColor)
                .foregroundColor(.primary)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 0)
    }
}
