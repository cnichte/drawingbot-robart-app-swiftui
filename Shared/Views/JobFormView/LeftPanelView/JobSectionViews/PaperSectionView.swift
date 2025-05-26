//
//  PaperSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// PaperSectionView.swift
import SwiftUI

struct PaperSectionView: View {
    @EnvironmentObject var model: SVGInspectorModel
    @EnvironmentObject var assetStores: AssetStores
    
    var onUpdate: () -> Void // callback

    private let customPaperID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    var body: some View {
        CollapsibleSection(title: "Papier", systemImage: "doc.plaintext") {
            VStack(alignment: .leading, spacing: 10) {
                
                HStack {
                    Picker("Papier-Vorlage", selection: $model.jobBox.paperDataID) {
                        Text("– Kein Papier –").tag(Optional(PaperData.default.id))

                        ForEach(assetStores.paperStore.items) { paper in
                            Text(paper.name).tag(Optional(paper.id))
                        }

                        Divider()

                        Text("➕ Eigenes Papier").tag(Optional(customPaperID))
                    }
                    .pickerStyle(.menu)
                    .onChange(of: model.jobBox.paperDataID) { _, newID in
                        if let id = newID {
                            if id == customPaperID {
                                // Eigenes Papier bleibt erhalten
                                appLog(.info, "✏️ Eigenes Papier ausgewählt")
                            } else if id == PaperData.default.id {
                                model.jobBox.paperData = .default
                            } else if let selectedPaper = assetStores.paperStore.items.first(where: { $0.id == id }) {
                                model.jobBox.paperData = selectedPaper
                            }
                            model.syncJobBoxBack() // Synchronisiere Änderungen zurück in job
                        }
                    }
                    
                    // ➕ Button anzeigen, wenn Eigenes Papier gewählt
                    if isCustomPaperSelected {
                        Button(action: saveCustomPaperAsTemplate) {
                            Image(systemName: "plus.circle")
                                .font(.title3)
                        }
                        .help("Eigenes Papier als Vorlage speichern")
                    }
                }
                .padding(.bottom, 8)

                Divider()

                Group {
                    Tools.textField(label: "Name", value: $model.job.paperData.name)
                        .disabled(!isCustomPaperSelected)
                    Tools.textField(label: "Gewicht (g/m²)", value: $model.job.paperData.weight)
                        .disabled(!isCustomPaperSelected)
                    Tools.textField(label: "Farbe", value: $model.job.paperData.color)
                        .disabled(!isCustomPaperSelected)
                    Tools.textField(label: "Hersteller", value: $model.job.paperData.hersteller)
                        .disabled(!isCustomPaperSelected)
                    Tools.textField(label: "Shoplink", value: $model.job.paperData.shoplink)
                        .disabled(!isCustomPaperSelected)
                    Tools.textField(label: "Beschreibung", value: $model.job.paperData.description)
                        .disabled(!isCustomPaperSelected)
                }
                .onChange(of: model.job.paperData) {
                    // onUpdate()
                }

                Divider()

                HStack {
                    Text("Breite (mm)")
                    Tools.doubleTextField(label: "Breite", value: $model.job.paperData.paperFormat.width)
                        .disabled(!isCustomPaperSelected)
                }
                .onChange(of: model.job.paperData.paperFormat.width) {
                    // onUpdate()
                }

                HStack {
                    Text("Höhe (mm)")
                    Tools.doubleTextField(label: "Höhe", value: $model.job.paperData.paperFormat.height)
                        .disabled(!isCustomPaperSelected)
                }
                .onChange(of: model.job.paperData.paperFormat.height) {
                    // onUpdate()
                }

                HStack {
                    Picker("Orientierung", selection: $model.job.paperOrientation) {
                        Text("Hochformat").tag(PaperOrientation.portrait)
                        Text("Querformat").tag(PaperOrientation.landscape)
                    }
                    .pickerStyle(.segmented)
                }
                .onChange(of: model.job.paperOrientation) {
                    // onUpdate()
                }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Helpers

    private var isCustomPaperSelected: Bool {
        return model.job.paperDataID == customPaperID
    }

    private func saveCustomPaperAsTemplate() {
        let newPaper = PaperData(
            id: UUID(), // <<< neue eindeutige ID
            name: model.job.paperData.name,
            weight: model.job.paperData.weight,
            color: model.job.paperData.color,
            hersteller: model.job.paperData.hersteller,
            shoplink: model.job.paperData.shoplink,
            description: model.job.paperData.description,
            paperFormat: model.job.paperData.paperFormat
        )

        assetStores.paperStore.items.append(newPaper)
        Task {
            await assetStores.paperStore.save(item: newPaper, fileName: newPaper.id.uuidString)
            appLog(.info, "✅ Papier-Vorlage gespeichert: \(newPaper.name)")
        }

        // aktuelle Auswahl auf das neue Papier setzen
        model.job.paperDataID = newPaper.id
        model.job.paperData = newPaper
        // onUpdate()
    }
}
