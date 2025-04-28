//
//  ActionsSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//
import SwiftUI

struct ActionsSectionView: View {
    @Binding var currentJob: PlotJobData
    @EnvironmentObject var store: GenericStore<PlotJobData>

    var body: some View {
        CollapsibleSection(title: "Actions", systemImage: "figure.run.circle", toolbar: { EmptyView() }) {
            VStack(alignment: .leading) {
                Text("Hier kommen aktionen rein")
            }
        }
    }
}
