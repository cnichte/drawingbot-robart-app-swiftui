//
//  JobRow.swift
//  Robart
//
//  Created by Carsten Nichte on 16.04.25.
//

// JobRow.swift
import SwiftUI

struct JobRow: View {
    let job: JobData
    let onSelect: (JobData) -> Void
    let onDelete: (JobData) -> Void

    var body: some View {
        HStack {
            Button {
                onSelect(job)
            } label: {
                VStack(alignment: .leading) {
                    Text(job.name).bold()
                    if !job.description.isEmpty {
                        Text(job.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    if job.isActive {
                        Text("✅ Aktiv")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                onDelete(job)
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
