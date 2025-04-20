//
//  UnassignedSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 16.04.25.
//

// UnassignedSectionView.swift
import SwiftUI

struct UnassignedSectionView: View {
    let jobs: [PlotJobData]
    let onDrop: ([PlotJobData], CGPoint) -> Bool
    let onJobSelected: (PlotJobData) -> Void
    let onDeleteJob: (PlotJobData) -> Void

    @State private var isTargeted = false

    var body: some View {
        CollapsibleSection(title: "Nicht zugeordnete Jobs", systemImage: "tray") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(jobs) { job in
                    JobRow(job: job, onSelect: onJobSelected, onDelete: onDeleteJob)
                        .draggable(job)
                }
            }
            .padding()
            .background(isTargeted ? Color.accentColor.opacity(0.2) : Color.clear)
            .animation(.easeInOut, value: isTargeted)
            .dropDestination(for: PlotJobData.self) { items, location in
                onDrop(items, location)
            } isTargeted: { active in
                isTargeted = active
            }
        }
    }
}
