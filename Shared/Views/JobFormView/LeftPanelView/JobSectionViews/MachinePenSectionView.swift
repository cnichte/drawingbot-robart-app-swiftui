//
//  MachinePenSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// MachinePenSectionView.swift
import SwiftUI

struct MachinePenSectionView: View {
    @EnvironmentObject var model: SVGInspectorModel
    @EnvironmentObject var assetStores: AssetStores

    var body: some View {
        CollapsibleSection(
            title: "Maschine | Stifte",
            systemImage: "pencil.tip",
            toolbar: { EmptyView() }
        ) {
            if let machine = model.machine, machine.penCount > 0 {
                let penSlots = machine.penCount

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<penSlots, id: \.self) { index in
                        PenSlotView(
                            penID: Binding(
                                get: { index < model.jobBox.penConfigurationIDs.count ? model.jobBox.penConfigurationIDs[index] : nil },
                                set: { newID in
                                    // appLog(.info, "Binding set penID[\(index)] to: \(newID?.uuidString ?? "nil")")
                                    if index < model.jobBox.penConfigurationIDs.count {
                                        model.jobBox.penConfigurationIDs[index] = newID
                                        if index < model.jobBox.penConfiguration.count {
                                            model.jobBox.penConfiguration[index].penID = newID
                                        }
                                    } else {
                                        model.jobBox.penConfigurationIDs.append(newID)
                                        model.jobBox.penConfiguration.append(PenConfiguration(
                                            penSVGLayerAssignment: .toLayer,
                                            penID: newID,
                                            color: "",
                                            layer: "",
                                            angle: 90
                                        ))
                                    }
                                    model.syncJobBoxBack()
                                }
                            ),
                            penColorID: Binding(
                                get: { index < model.jobBox.penConfiguration.count ? model.jobBox.penConfiguration[index].penColorID : nil },
                                set: { newID in
                                    // appLog(.info, "Binding set penColorID[\(index)] to: \(newID?.uuidString ?? "nil")")
                                    if index < model.jobBox.penConfiguration.count {
                                        model.jobBox.penConfiguration[index].penColorID = newID
                                    }
                                    model.syncJobBoxBack()
                                }
                            ),
                            penVarianteID: Binding(
                                get: { index < model.jobBox.penConfiguration.count ? model.jobBox.penConfiguration[index].penVarianteID : nil },
                                set: { newID in
                                    // appLog(.info, "Binding set penVarianteID[\(index)] to: \(newID?.uuidString ?? "nil")")
                                    if index < model.jobBox.penConfiguration.count {
                                        model.jobBox.penConfiguration[index].penVarianteID = newID
                                    }
                                    model.syncJobBoxBack()
                                }
                            ),
                            penSVGLayerAssignment: Binding(
                                get: { index < model.jobBox.penConfiguration.count ? model.jobBox.penConfiguration[index].penSVGLayerAssignment : .toLayer },
                                set: { newValue in
                                    // appLog(.info, "Binding set penSVGLayerAssignment[\(index)] to: \(newValue.rawValue)")
                                    if index < model.jobBox.penConfiguration.count {
                                        model.jobBox.penConfiguration[index].penSVGLayerAssignment = newValue
                                    }
                                    model.syncJobBoxBack()
                                }
                            ),
                            layer: Binding(
                                get: { index < model.jobBox.penConfiguration.count ? model.jobBox.penConfiguration[index].layer : "" },
                                set: { newValue in
                                    // appLog(.info, "Binding set layer[\(index)] to: \(newValue)")
                                    if index < model.jobBox.penConfiguration.count {
                                        model.jobBox.penConfiguration[index].layer = newValue
                                    }
                                    model.syncJobBoxBack()
                                }
                            ),
                            color: Binding(
                                get: { index < model.jobBox.penConfiguration.count ? model.jobBox.penConfiguration[index].color : "" },
                                set: { newValue in
                                    // appLog(.info, "Binding set color[\(index)] to: \(newValue)")
                                    if index < model.jobBox.penConfiguration.count {
                                        model.jobBox.penConfiguration[index].color = newValue
                                    }
                                    model.syncJobBoxBack()
                                }
                            ),
                            angle: Binding(
                                get: { index < model.jobBox.penConfiguration.count ? model.jobBox.penConfiguration[index].angle : 90 },
                                set: { newValue in
                                    // appLog(.info, "Binding set angle[\(index)] to: \(newValue)")
                                    if index < model.jobBox.penConfiguration.count {
                                        model.jobBox.penConfiguration[index].angle = newValue
                                    }
                                    model.syncJobBoxBack()
                                }
                            ),
                            pens: assetStores.pensStore.items
                        )
                        .padding(8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("Bitte zuerst eine Maschine auswählen oder Maschine hat keine Stift-Slots.")
                    .foregroundColor(.secondary)
            }
        }
        .task {
            await ensurePenConfiguration()
        }
        .onChange(of: model.machine) { _, _ in
            Task { await ensurePenConfiguration() }
        }
        .onChange(of: model.jobBox.penConfigurationIDs) { _, newValue in
            // appLog(.info, "penConfigurationIDs changed: \(newValue.map { $0?.uuidString ?? "nil" })")
            synchronizePenConfiguration()
            model.syncJobBoxBack()
            // Task { await model.save(using: assetStores.plotJobStore) }
        }
        .onChange(of: model.jobBox.penConfiguration) { _, newValue in
            // appLog(.info, "penConfiguration changed: \(newValue.map { "penID=\($0.penID?.uuidString ?? "nil")" })")
            model.syncJobBoxBack()
            // Task { await model.save(using: assetStores.plotJobStore) }
        }
        .onAppear {
            // appLog(.info, "Available pens: \(assetStores.pensStore.items.map { "id=\($0.id.uuidString), name=\($0.name)" })")
        }
    }

    @MainActor
    private func ensurePenConfiguration() async {
        guard let machine = model.machine else {
            model.jobBox.penConfiguration = []
            model.jobBox.penConfigurationIDs = []
            model.syncJobBoxBack()
            return
        }

        let desiredCount = machine.penCount
        var updatedConfigs = model.jobBox.penConfiguration
        var updatedIDs = model.jobBox.penConfigurationIDs

        // Validiere penConfigurationIDs gegen verfügbare Pens
        let validPenIDs = Set(assetStores.pensStore.items.map { $0.id })
        updatedIDs = updatedIDs.map { id in
            if let id = id, validPenIDs.contains(id) {
                return id
            } else {
                // appLog(.warning, "Invalid penID: \(id?.uuidString ?? "nil"), resetting to nil")
                return nil
            }
        }

        // Stelle sicher, dass die Länge von penConfiguration und penConfigurationIDs gleich ist
        if updatedConfigs.count < desiredCount {
            updatedConfigs.append(contentsOf: (updatedConfigs.count..<desiredCount).map { _ in
                PenConfiguration(
                    penSVGLayerAssignment: .toLayer,
                    color: "",
                    layer: "",
                    angle: 90
                )
            })
            updatedIDs.append(contentsOf: Array(repeating: nil, count: desiredCount - updatedIDs.count))
        } else if updatedConfigs.count > desiredCount {
            updatedConfigs = Array(updatedConfigs.prefix(desiredCount))
            updatedIDs = Array(updatedIDs.prefix(desiredCount))
        }

        // Synchronisiere penConfiguration.penID mit penConfigurationIDs
        for index in 0..<min(updatedConfigs.count, updatedIDs.count) {
            updatedConfigs[index].penID = updatedIDs[index]
        }

        model.jobBox.penConfiguration = updatedConfigs
        model.jobBox.penConfigurationIDs = updatedIDs
        model.syncJobBoxBack()
        // appLog(.info, "Ensured penConfiguration: \(updatedConfigs.count) slots, IDs: \(updatedIDs.map { $0?.uuidString ?? "nil" })")
    }

    private func synchronizePenConfiguration() {
        var updatedConfigs = model.jobBox.penConfiguration
        let ids = model.jobBox.penConfigurationIDs
        let validPenIDs = Set(assetStores.pensStore.items.map { $0.id })

        // Stelle sicher, dass penConfiguration.penID mit penConfigurationIDs übereinstimmt
        for index in 0..<min(updatedConfigs.count, ids.count) {
            let id = ids[index]
            if let id = id, validPenIDs.contains(id) {
                updatedConfigs[index].penID = id
            } else {
                updatedConfigs[index].penID = nil
            }
        }

        model.jobBox.penConfiguration = updatedConfigs
        // appLog(.info, "Synchronized penConfiguration: \(updatedConfigs.map { "penID=\($0.penID?.uuidString ?? "nil")" })")
    }
}

// MARK: - PenSlotView

// MachinePenSectionView.swift (PenSlotView)
struct PenSlotView: View {
    @Binding var penID: UUID?
    @Binding var penColorID: UUID?
    @Binding var penVarianteID: UUID?
    @Binding var penSVGLayerAssignment: PenSVGLayerAssignment
    @Binding var layer: String
    @Binding var color: String
    @Binding var angle: Int
    let pens: [PenData]

    var body: some View {
        let selectedPen = pens.first(where: { $0.id == penID })
        let availableColors = selectedPen?.farben ?? []
        let availableVarianten = selectedPen?.varianten ?? []

        let selectedColor = availableColors.first(where: { $0.id == penColorID })
        let selectedVariante = availableVarianten.first(where: { $0.id == penVarianteID })

        VStack(alignment: .leading, spacing: 8) {
            Text("Slot \(UUID().uuidString.prefix(4))").font(.headline)

            Picker("Stift", selection: $penID) {
                Text("– Kein Stift –").tag(nil as UUID?)
                ForEach(pens) { pen in
                    Text(pen.name).tag(Optional(pen.id))
                }
            }
            .onChange(of: penID) { _, newID in
                // appLog(.info, "Picker penID changed to: \(newID?.uuidString ?? "nil")")
                penColorID = nil
                penVarianteID = nil
            }
            .onAppear {
                // appLog(.info, "PenSlotView penID: \(penID?.uuidString ?? "nil"), Available pen IDs: \(pens.map { $0.id.uuidString })")
                if let id = penID, !pens.contains(where: { $0.id == id }) {
                    // appLog(.warning, "PenID \(id.uuidString) not found in pens, resetting to nil")
                    penID = nil
                }
            }

            if !availableColors.isEmpty {
                Picker("Farbe", selection: $penColorID) {
                    Text("– Keine –").tag(nil as UUID?)
                    ForEach(availableColors) { color in
                        let preview = Color(color.wert) ?? .clear
                        Text("\(color.name)  \(color.wert)")
                            .tag(Optional(color.id))
                            .foregroundColor(preview)
                    }
                }
                .onChange(of: penColorID) { _, newID in
                    // appLog(.info, "Picker penColorID changed to: \(newID?.uuidString ?? "nil")")
                }
                .onAppear {
                    // appLog(.info, "PenSlotView penColorID: \(penColorID?.uuidString ?? "nil"), Available color IDs: \(availableColors.map { $0.id.uuidString })")
                    if let id = penColorID, !availableColors.contains(where: { $0.id == id }) {
                        // appLog(.warning, "PenColorID \(id.uuidString) not found in colors, resetting to nil")
                        penColorID = nil
                    }
                }

                if let color = selectedColor {
                    HStack(spacing: 8) {
                        Text("Hex: \(color.wert)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Circle()
                            .fill(Color(color.wert) ?? .clear)
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.gray.opacity(0.3)))
                    }
                }
            }

            if !availableVarianten.isEmpty {
                Picker("Variante", selection: $penVarianteID) {
                    Text("– Keine –").tag(nil as UUID?)
                    ForEach(availableVarianten) { variant in
                        Text(variant.name).tag(Optional(variant.id))
                    }
                }
                .onChange(of: penVarianteID) { _, newID in
                    // appLog(.info, "Picker penVarianteID changed to: \(newID?.uuidString ?? "nil")")
                }
                .onAppear {
                    // appLog(.info, "PenSlotView penVarianteID: \(penVarianteID?.uuidString ?? "nil"), Available variant IDs: \(availableVarianten.map { $0.id.uuidString })")
                    if let id = penVarianteID, !availableVarianten.contains(where: { $0.id == id }) {
                        // appLog(.warning, "PenVarianteID \(id.uuidString) not found in variants, resetting to nil")
                        penVarianteID = nil
                    }
                }

                if let variant = selectedVariante {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spitze: \(variant.spitzeSize.x.clean) × \(variant.spitzeSize.y.clean) \(variant.spitzeUnit.name)")
                        Text("Reichweite: \(variant.reichweite.clean) \(variant.reichweiteUnit.name)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }

            Picker("Zuordnung", selection: $penSVGLayerAssignment) {
                Text("Ebene").tag(PenSVGLayerAssignment.toLayer)
                Text("Farbe").tag(PenSVGLayerAssignment.toColor)
            }
            .pickerStyle(.segmented)
            .onChange(of: penSVGLayerAssignment) { _, newValue in
                // appLog(.info, "Picker penSVGLayerAssignment changed to: \(newValue.rawValue)")
            }

            if penSVGLayerAssignment == .toLayer {
                TextField("Ebene", text: $layer)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField("Farbe im SVG", text: $layer)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
