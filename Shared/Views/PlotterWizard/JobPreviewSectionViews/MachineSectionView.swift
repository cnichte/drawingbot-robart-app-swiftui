//
//  MachineSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// MachineSectionView.swift
import SwiftUI

struct MachineSectionView: View {
    @Binding var currentJob: PlotJobData
    @EnvironmentObject var store: GenericStore<PlotJobData>

    var body: some View {
        CollapsibleSection(title: "Maschine", systemImage: "gearshape.2") {
            VStack(alignment: .leading) {
                HStack {
                    Text("Origin X")
                    TextField("X", value: $currentJob.origin.x, formatter: NumberFormatter())
                }
                HStack {
                    Text("Origin Y")
                    TextField("Y", value: $currentJob.origin.y, formatter: NumberFormatter())
                }
                Toggle("Aktiv", isOn: $currentJob.isActive)
            }
        }
    }
}
