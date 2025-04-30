//
//  ProjectSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 16.04.25.
//

// ProjectSectionView.swift
import SwiftUI

struct ProjectSectionView: View {
    let project: ProjectData
    let onDrop: ([JobData], CGPoint) -> Bool
    let onJobSelected: (JobData) -> Void
    let onDeleteJob: (JobData) -> Void

    @State private var isTargeted = false

    var body: some View {
        CollapsibleSection(title: project.name, systemImage: "folder", toolbar: { EmptyView() }) {
            VStack(alignment: .leading, spacing: 8) {
                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

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
                    ForEach(project.jobs) { job in
                        JobRow(job: job, onSelect: onJobSelected, onDelete: onDeleteJob)
                            .draggable(job)
                    }
                }
            }
            .padding()
            .background(isTargeted ? Color.accentColor.opacity(0.2) : Color.clear)
            .animation(.easeInOut, value: isTargeted)
            .dropZone(of: .plotJob, isTargeted: $isTargeted, onDrop: onDrop)
        }
    }
}
