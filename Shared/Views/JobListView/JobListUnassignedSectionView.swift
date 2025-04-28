//
//  UnassignedSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 16.04.25.
//

// UnassignedSectionView.swift
import SwiftUI

struct JobListUnassignedSectionView: View {
    var title: String
    var jobs: [PlotJobData]
    var thumbnailProvider: (PlotJobData) -> Image?
    var onDrop: ([PlotJobData], CGPoint) -> Bool
    var onJobSelected: (PlotJobData) -> Void
    var onDeleteJob: (PlotJobData) -> Void

    @State private var isTargeted = false

    var body: some View {
        CollapsibleSection(title: title, systemImage: "tray") {
            Group {
                if jobs.isEmpty {
                    VStack {
                        Spacer()
                        Text("Ziehe hierher, um Jobs zuzuordnen")
                            .foregroundColor(.secondary)
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 120)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                        ForEach(jobs) { job in
                            VStack {
                                if let image = thumbnailProvider?(job) {
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
                                    .padding(.top, 4)
                            }
                            .onTapGesture {
                                onJobSelected(job)
                            }
                            .draggable(job)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            .background(isTargeted ? Color.accentColor.opacity(0.2) : Color.clear)
            .animation(.easeInOut, value: isTargeted)
            .dropZone(of: .plotJob, isTargeted: $isTargeted, onDrop: onDrop)
        }
    }
}
