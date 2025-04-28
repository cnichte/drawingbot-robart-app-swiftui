//
//  JobCardView.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// JobCardView.swift
import SwiftUI

struct JobCardView: View {
    let job: PlotJobData
    let thumbnail: Image?
    let onSelect: (PlotJobData) -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 8) {
            if let image = thumbnail {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 100)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.secondary)
                            .font(.largeTitle)
                    )
            }

            Text(job.name)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)

            if !job.description.isEmpty {
                Text(job.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .help(job.description) // Tooltip auf macOS
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
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
