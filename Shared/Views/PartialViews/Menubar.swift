//
//  Menubar.swift
//  Robart
//
//  Created by Carsten Nichte on 29.04.25.
//

// Menubar.swift
import SwiftUI

struct Menubar<Toolbar: View>: View {
    var title: String?
    var systemImage: String?
    let toolbar: Toolbar

    init(
        title: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder toolbar: () -> Toolbar = { EmptyView() },
    ) {
        self.title = title
        self.systemImage = systemImage
        self.toolbar = toolbar()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                }
                if let title = title {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                }
                Spacer()
                
                toolbar
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ColorHelper.backgroundColor)
            .foregroundColor(.primary)
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
}
