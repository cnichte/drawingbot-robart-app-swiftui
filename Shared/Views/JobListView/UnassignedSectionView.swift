//
//  UnassignedSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 16.04.25.
//

// UnassignedSectionView.swift
import SwiftUI

struct UnassignedSectionView: View {
    let title: String
    let jobs: [PlotJobData]
    let onDrop: ([PlotJobData], CGPoint) -> Bool
    let onJobSelected: (PlotJobData) -> Void
    let onDeleteJob: (PlotJobData) -> Void

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
                    ForEach(jobs) { job in
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
