//
//  PaperSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// PaperSectionView.swift
import SwiftUI

struct PaperSectionView: View {
    @Binding var currentJob: PlotJobData
    @EnvironmentObject var assetStores: AssetStores
    var onUpdate: () -> Void

    var body: some View {
        CollapsibleSection(title: "Papier", systemImage: "doc.plaintext") {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Papier auswählen", selection: Binding<UUID?>(
                    get: { currentJob.paperFormatID },
                    set: { newID in
                        currentJob.paperFormatID = newID
                        if let id = newID, let selectedPaper = assetStores.paperStore.items.first(where: { $0.id == id }) {
                            currentJob.paper = selectedPaper
                            onUpdate()
                        }
                    }
                )) {
                    ForEach(assetStores.paperStore.items) { paper in
                        Text(paper.name).tag(Optional(paper.id))
                    }
                }
                .pickerStyle(.menu)
                .padding(.bottom, 8)

                Divider()

                HStack {
                    Text("Papier")
                    Tools.textField(label: "Papier Name", value: $currentJob.paper.name)
                }
                .onChange(of: currentJob.paper.name) { onUpdate() }

                HStack {
                    Text("Breite")
                    Tools.doubleTextField(label: "Breite", value: $currentJob.paper.paperFormat.width)
                }
                .onChange(of: currentJob.paper.paperFormat.width) { onUpdate() }

                HStack {
                    Text("Höhe")
                    Tools.doubleTextField(label: "Höhe", value: $currentJob.paper.paperFormat.height)
                }
                .onChange(of: currentJob.paper.paperFormat.height) { onUpdate() }

                HStack {
                    Text("Orientierung")
                    Picker("Orientierung", selection: $currentJob.paperOrientation) {
                        Text("Hochformat").tag(PaperOrientation.portrait)
                        Text("Querformat").tag(PaperOrientation.landscape)
                    }
                    .pickerStyle(.segmented)
                }
                .onChange(of: currentJob.paperOrientation) { onUpdate() }
            }
        }
    }
}
