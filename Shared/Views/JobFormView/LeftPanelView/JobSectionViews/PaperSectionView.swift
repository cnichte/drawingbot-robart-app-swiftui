//
//  PaperSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// PaperSectionView.swift
import SwiftUI

struct PaperSectionView: View {
    @Binding var currentJob: JobData
    @EnvironmentObject var assetStores: AssetStores
    var onUpdate: () -> Void

    private let customPaperID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    var body: some View {
        CollapsibleSection(title: "Papier", systemImage: "doc.plaintext") {
            VStack(alignment: .leading, spacing: 10) {
                
                HStack {
                    Picker("Papier-Vorlage", selection: Binding<UUID?>(
                        get: { currentJob.paperFormatID },
                        set: { newID in
                            currentJob.paperFormatID = newID
                            if let id = newID {
                                if id == customPaperID {
                                    // Eigenes Papier bleibt erhalten
                                    appLog(.info, "✏️ Eigenes Papier ausgewählt")
                                } else if let selectedPaper = assetStores.paperStore.items.first(where: { $0.id == id }) {
                                    currentJob.paper = selectedPaper
                                    onUpdate()
                                }
                            }
                        }
                    )) {
                        ForEach(assetStores.paperStore.items) { paper in
                            Text(paper.name).tag(Optional(paper.id))
                        }
                        Divider()
                        Text("➕ Eigenes Papier").tag(Optional(customPaperID))
                    }
                    .pickerStyle(.menu)

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
                    Tools.textField(label: "Name", value: $currentJob.paper.name)
                        .disabled(!isCustomPaperSelected)
                    Tools.textField(label: "Gewicht (g/m²)", value: $currentJob.paper.weight)
                        .disabled(!isCustomPaperSelected)
                    Tools.textField(label: "Farbe", value: $currentJob.paper.color)
                        .disabled(!isCustomPaperSelected)
                    Tools.textField(label: "Hersteller", value: $currentJob.paper.hersteller)
                        .disabled(!isCustomPaperSelected)
                    Tools.textField(label: "Shoplink", value: $currentJob.paper.shoplink)
                        .disabled(!isCustomPaperSelected)
                    Tools.textField(label: "Beschreibung", value: $currentJob.paper.description)
                        .disabled(!isCustomPaperSelected)
                }
                .onChange(of: currentJob.paper) { onUpdate() }

                Divider()

                HStack {
                    Text("Breite (mm)")
                    Tools.doubleTextField(label: "Breite", value: $currentJob.paper.paperFormat.width)
                        .disabled(!isCustomPaperSelected)
                }
                .onChange(of: currentJob.paper.paperFormat.width) { onUpdate() }

                HStack {
                    Text("Höhe (mm)")
                    Tools.doubleTextField(label: "Höhe", value: $currentJob.paper.paperFormat.height)
                        .disabled(!isCustomPaperSelected)
                }
                .onChange(of: currentJob.paper.paperFormat.height) { onUpdate() }

                HStack {
                    Picker("Orientierung", selection: $currentJob.paperOrientation) {
                        Text("Hochformat").tag(PaperOrientation.portrait)
                        Text("Querformat").tag(PaperOrientation.landscape)
                    }
                    .pickerStyle(.segmented)
                }
                .onChange(of: currentJob.paperOrientation) { onUpdate() }
            }
            .padding(.top, 4)
        }
    }

    // MARK: - Helpers

    private var isCustomPaperSelected: Bool {
        return currentJob.paperFormatID == customPaperID
    }

    private func saveCustomPaperAsTemplate() {
        let newPaper = PaperData(
            id: UUID(), // <<< neue eindeutige ID
            name: currentJob.paper.name,
            weight: currentJob.paper.weight,
            color: currentJob.paper.color,
            hersteller: currentJob.paper.hersteller,
            shoplink: currentJob.paper.shoplink,
            description: currentJob.paper.description,
            paperFormat: currentJob.paper.paperFormat
        )

        assetStores.paperStore.items.append(newPaper)
        Task {
            await assetStores.paperStore.save(item: newPaper, fileName: newPaper.id.uuidString)
            appLog(.info, "✅ Papier-Vorlage gespeichert: \(newPaper.name)")
        }

        // aktuelle Auswahl auf das neue Papier setzen
        currentJob.paperFormatID = newPaper.id
        currentJob.paper = newPaper
        onUpdate()
    }
}
