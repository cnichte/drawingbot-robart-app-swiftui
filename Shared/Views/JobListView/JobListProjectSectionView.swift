//
//  ProjectSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

import SwiftUI

struct ProjectSectionView: View {
    var project: ProjectData
    var thumbnailProvider: (PlotJobData) -> Image? // 👈 NEU
    var onDrop: ([PlotJobData], CGPoint) -> Bool
    var onJobSelected: (PlotJobData) -> Void
    var onDeleteJob: (PlotJobData) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(project.name)
                .font(.title2.bold())
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                ForEach(project.jobs) { job in
                    VStack {
                        if let image = thumbnailProvider(job) {
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
                }
            }
            .padding(.horizontal)
        }
        .onDrop(of: ["public.text"], isTargeted: nil) { providers, location in
            // Dein Drag & Drop Handling
            return false
        }
    }
}
