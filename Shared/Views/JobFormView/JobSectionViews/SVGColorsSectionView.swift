//
//  SVGColorsSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 30.04.25.
//

import SwiftUI

struct SVGColorsSectionView: View {
    @Binding var currentJob: PlotJobData
    // @EnvironmentObject var jobStore: GenericStore<PlotJobData>

    var body: some View {
        CollapsibleSection(title: "SVG Farben | Stifte", systemImage: "doc.plaintext", toolbar: { EmptyView() }) {
            VStack(alignment: .leading) {
                Text("Content here")
            }
            .textFieldStyle(.roundedBorder)
        }
    }
}
