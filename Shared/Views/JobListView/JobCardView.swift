//
//  JobCardView.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// JobCardView.swift
import SwiftUI

struct JobCardView: View {
    let job: JobData
    let thumbnail: Image?
    let isSelected: Bool
    let onSelect: (JobData) -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 8) {
            if let image = thumbnail {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .cornerRadius(8)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                            .font(.largeTitle)
                    )
            }

            Text(job.name)
                .font(.headline)
                .lineLimit(1)

            if !job.description.isEmpty {
                Text(job.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.horizontal, 4)
                    .help(job.description) // Tooltip
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ColorHelper.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2) // Auswahl-Rand
                )
        )
        .shadow(color: isHovering ? Color.black.opacity(0.2) : Color.clear, radius: 8, x: 0, y: 4)
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onSelect(job)
        }
        .draggable(job)
    }
}
