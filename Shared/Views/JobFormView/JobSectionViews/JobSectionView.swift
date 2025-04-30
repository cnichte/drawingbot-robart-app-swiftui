//
//  JobSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// JobSectionView.swift
import SwiftUI

struct JobSectionView: View {
    @Binding var currentJob: PlotJobData
    // @EnvironmentObject var jobStore: GenericStore<PlotJobData>

    var body: some View {
        CollapsibleSection(title: "Job", systemImage: "doc.plaintext", toolbar: { EmptyView() }) {
            VStack(alignment: .leading) {
                TextField("Name", text: $currentJob.name)
                TextEditor(text: $currentJob.description)
                    .frame(minHeight: 80)
                    .padding(4)
                    .background(ColorHelper.backgroundColor)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3))
                    )
            }
            .textFieldStyle(.roundedBorder)
        }
    }
}
