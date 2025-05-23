//
//  ActionsSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// ActionsSectionView.swift
import SwiftUI

struct ActionsSectionView: View {
    
    @EnvironmentObject var model: SVGInspectorModel
    @EnvironmentObject var store: GenericStore<JobData>

    var body: some View {
        CollapsibleSection(title: "Actions", systemImage: "figure.run.circle", toolbar: { EmptyView() }) {
            VStack(alignment: .leading) {
                Text("Hier kommen aktionen rein")
            }
        }
    }
}
