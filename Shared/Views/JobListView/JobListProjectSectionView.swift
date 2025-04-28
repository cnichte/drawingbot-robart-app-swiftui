//
//  JobListProjectSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// JobListProjectSectionView.swift
import SwiftUI

struct JobListProjectSectionView: View {
    let project: ProjectData
    var selectedJobID: UUID?
    var viewMode: JobListViewMode
    var thumbnailProvider: (PlotJobData) -> Image?
    var onDrop: ([PlotJobData], CGPoint) -> Bool
    var onJobSelected: (PlotJobData) -> Void
    var onDeleteJob: (PlotJobData) -> Void

    @State private var isTargeted = false

    var body: some View {
        CollapsibleSection(title: project.name, systemImage: "folder") {
            VStack(alignment: .leading, spacing: 8) {
                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                content
            }
            .padding()
            .background(isTargeted ? Color.accentColor.opacity(0.2) : Color.clear)
            .animation(.easeInOut, value: isTargeted)
            .dropZone(of: .plotJob, isTargeted: $isTargeted, onDrop: onDrop)
        }
    }

    @ViewBuilder
    private var content: some View {
        if project.jobs.isEmpty {
            VStack {
                Spacer()
                Text("Ziehe hierher, um Jobs zuzuordnen")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 120)
        } else {
            switch viewMode {
            case .list:
                LazyVStack(spacing: 12) {
                    ForEach(project.jobs) { job in
                        HStack(spacing: 12) {
                            thumbnailProvider(job)?
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .cornerRadius(6)
                                .clipped()

                            VStack(alignment: .leading, spacing: 4) {
                                Text(job.name)
                                    .font(.headline)
                                if !job.description.isEmpty {
                                    Text(job.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(6)
                        .background(selectedJobID == job.id ? Color.accentColor.opacity(0.15) : Color.clear)
                        .cornerRadius(8)
                        .onTapGesture {
                            onJobSelected(job)
                        }
                        .draggable(job)
                    }
                }
            case .grid:
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(project.jobs) { job in
                        JobCardView(
                            job: job,
                            thumbnail: thumbnailProvider(job),
                            isSelected: selectedJobID == job.id,
                            onSelect: onJobSelected
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}
