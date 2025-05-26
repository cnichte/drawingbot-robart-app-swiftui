//
//  JobListUnassignedSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 16.04.25.
//

// JobListUnassignedSectionView.swift
import SwiftUI

struct JobListUnassignedSectionView: View {
    var title: String
    @Binding var jobs: [JobData]
    var selectedJobID: UUID?
    var viewMode: JobListViewMode
    var thumbnailProvider: (JobData) -> Image?
    var onDrop: ([JobData], CGPoint) -> Bool
    var onJobSelected: (JobData) -> Void
    var onDeleteJob: (JobData) -> Void

    @State private var isTargeted = false

    var body: some View {
        CollapsibleSection(title: title, systemImage: "tray") {
            content
                .padding()
                .background(isTargeted ? Color.accentColor.opacity(0.2) : Color.clear)
                .animation(.easeInOut, value: isTargeted)
                .dropZone(of: .plotJob, isTargeted: $isTargeted, onDrop: onDrop)
        }
    }

    @ViewBuilder
    private var content: some View {
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
            switch viewMode {
            case .list:
                LazyVStack(spacing: 12) {
                    ForEach($jobs) { $job in
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
                    ForEach($jobs) { $job in
                        JobCardView(
                            job: $job,
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
