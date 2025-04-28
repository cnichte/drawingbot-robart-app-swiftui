//
//  CollapsibleSection.swift
//  Robart
//
//  Created by Carsten Nichte on 16.04.25.
//
// CollapsibleSection(title: "Papier-Einstellungen", systemImage: "doc.plaintext")

//  CollapsibleSection.swift
import SwiftUI

struct CollapsibleSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: Content

    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            // Header-Button
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: systemImage)
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(ColorHelper.backgroundColor)
                .foregroundColor(.primary)
            }
            .buttonStyle(.plain)

            // Inhalt
            if isExpanded {
                VStack {
                    content
                }
                .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading) // << minHeight hinzugefügt
                .padding(12)
                .background(ColorHelper.backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.gray.opacity(0.2))
        )
        .padding(.horizontal)
        .padding(.bottom, 0)
    }
}
