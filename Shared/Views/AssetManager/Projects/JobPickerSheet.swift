//
//  JobPickerSheet.swift
//  Robart
//
//  Created by Carsten Nichte on 20.04.25.
//

// MARK: - JobPickerSheet
import SwiftUI

struct JobPickerSheet: View {
    var allJobs: [PlotJobData]
    var assignedJobs: [PlotJobData]
    var onSelect: (PlotJobData) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                let assignedIDs = Set(assignedJobs.map { $0.id })
                let unassigned = allJobs.filter { !assignedIDs.contains($0.id) }

                if unassigned.isEmpty {
                    Text("Keine verfügbaren Jobs")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(unassigned) { job in
                        Button {
                            onSelect(job)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(job.name).bold()
                                if !job.description.isEmpty {
                                    Text(job.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Job zuweisen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", action: onCancel)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}
