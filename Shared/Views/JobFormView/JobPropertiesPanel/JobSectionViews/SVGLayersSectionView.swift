//
//  SVGLayersSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 30.04.25.
//

import SwiftUI

struct SVGLayersSectionView: View {
    @Binding var currentJob: JobData
    // @EnvironmentObject var jobStore: GenericStore<JobData>

    var body: some View {
        CollapsibleSection(title: "SVG Ebenen | Stifte", systemImage: "doc.plaintext", toolbar: { EmptyView() }) {
            VStack(alignment: .leading) {
                Text("Content here")
            }
            .textFieldStyle(.roundedBorder)
        }
    }
}
