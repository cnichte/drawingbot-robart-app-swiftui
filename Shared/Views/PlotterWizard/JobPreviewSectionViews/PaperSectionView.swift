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
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    var onUpdate: () -> Void

    var body: some View {
        CollapsibleSection(title: "Papier", systemImage: "doc.plaintext") {
            VStack(alignment: .leading, spacing: 10) {
                
                Picker("Papier auswählen", selection: Binding(
                    get: {
                        paperStore.items.first(where: { $0.name == currentJob.paperSize.name })?.id
                    },
                    set: { newID in
                        if let selectedPaper = paperStore.items.first(where: { $0.id == newID }) {
                            currentJob.paperSize.name = selectedPaper.name
                            currentJob.paperSize.width = selectedPaper.width
                            currentJob.paperSize.height = selectedPaper.height
                            onUpdate()
                        }
                    }
                )) {
                    ForEach(paperStore.items) { paper in
                        Text(paper.name).tag(paper.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .padding(.bottom, 8)

                Divider()
                
                HStack {
                    Text("Papiergröße-Name")
                    Tools.textField(label: "Papiergröße-Name", value: $currentJob.paperSize.name)
                }
                .onChange(of: currentJob.paperSize.name) { onUpdate() }
                
                HStack {
                    Text("Papiergröße-Breite")
                    Tools.doubleTextField(label: "Papiergröße-Breite", value: $currentJob.paperSize.width)
                }
                .onChange(of: currentJob.paperSize.width) { onUpdate() }
                
                HStack {
                    Text("Papiergröße-Höhe")
                    Tools.doubleTextField(label: "Papiergröße-Höhe", value: $currentJob.paperSize.height)
                }
                .onChange(of: currentJob.paperSize.height) { onUpdate() }
                
                HStack {
                    Text("Papier-Orientierung")
                    Tools.doubleTextField(label: "Papier-Orientierung", value: $currentJob.paperSize.orientation)
                }
                .onChange(of: currentJob.paperSize.orientation) { onUpdate() }
            }
        }
    }
}
