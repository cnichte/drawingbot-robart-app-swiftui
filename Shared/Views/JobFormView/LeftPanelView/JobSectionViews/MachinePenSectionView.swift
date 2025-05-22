//
//  PenSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// PenSectionView.swift
import SwiftUI

struct MachinePenSectionView: View {
    @Binding var currentJob: JobData
    @Binding var selectedMachine: MachineData?
    @EnvironmentObject var assetStores: AssetStores

    var body: some View {
        CollapsibleSection(
            title: "Maschine | Stifte",
            systemImage: "pencil.tip",
            toolbar: { EmptyView() }
        ) {
            if let machine = selectedMachine, machine.penCount > 0 {
                let penSlots = machine.penCount

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<penSlots, id: \.self) { index in
                        PenSlotView(
                            index: index,
                            penConfiguration: $currentJob.penConfiguration,
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
        .onChange(of: selectedMachine) { oldMachine, newMachine in
            appLog(.info, "PEN SECTION VIEW - MACHINE CHANGED: \(String(describing: newMachine?.penCount))")
            guard let newCount = newMachine?.penCount else {
                // Wenn keine Maschine ausgewählt ist, leere penConfiguration
                currentJob.penConfiguration = []
                return
            }

            // Synchronisiere penConfiguration mit der neuen penCount
            let currentCount = currentJob.penConfiguration.count
            if newCount != currentCount {
                var newConfigs = currentJob.penConfiguration
                if newCount > currentCount {
                    // Füge neue Slots hinzu
                    let additionalConfigs = (currentCount..<newCount).map { _ in
                        PenConfiguration(penSVGLayerAssignment: .toLayer, color: "", layer: "", angle: 90)
                    }
                    newConfigs.append(contentsOf: additionalConfigs)
                } else {
                    // Entferne überschüssige Slots
                    newConfigs = Array(newConfigs.prefix(newCount))
                }
                // Weise die aktualisierte Konfiguration zu, um Reaktivität auszulösen
                currentJob.penConfiguration = newConfigs
            }
        }
        .onAppear {
            // Initiale Synchronisation
            if let penCount = selectedMachine?.penCount {
                let currentCount = currentJob.penConfiguration.count
                if penCount != currentCount {
                    var newConfigs = currentJob.penConfiguration
                    if penCount > currentCount {
                        newConfigs.append(contentsOf: (currentCount..<penCount).map { _ in
                            PenConfiguration(penSVGLayerAssignment: .toLayer, color: "", layer: "", angle: 90)
                        })
                    } else {
                        newConfigs = Array(newConfigs.prefix(penCount))
                    }
                    currentJob.penConfiguration = newConfigs
                }
            }
        }
    }

    /// Stellt sicher, dass der Eintrag an Index `index` in `penConfiguration` vorhanden ist und wendet `update` an.
    private func updatePenConfiguration(index: Int, update: (inout PenConfiguration) -> Void) {
        var configs = currentJob.penConfiguration
        while configs.count <= index {
            configs.append(PenConfiguration(penSVGLayerAssignment: .toLayer, color: "", layer: "", angle: 90))
        }
        update(&configs[index])
        currentJob.penConfiguration = configs // Weise neuen Array zu, um Reaktivität sicherzustellen
    }
}

// Neue Unterkomponente für einen einzelnen Stift-Slot

struct PenSlotView: View {
    let index: Int
    @Binding var penConfiguration: [PenConfiguration]
    let pens: [PenData]

    var body: some View {
        let config = penConfiguration[safe: index] ?? PenConfiguration(penSVGLayerAssignment: .toLayer, color: "", layer: "", angle: 90)

        let selectedPen = pens.first(where: { $0.id == config.penID })
        let availableColors = selectedPen?.farben ?? []
        let availableVarianten = selectedPen?.varianten ?? []

        let selectedColor = availableColors.first(where: { $0.id == config.penColorID })
        let selectedVariante = availableVarianten.first(where: { $0.id == config.penVarianteID })

        VStack(alignment: .leading, spacing: 8) {
            Text("Slot \(index + 1)").font(.headline)

            Picker("Stift", selection: Binding(
                get: { config.penID ?? UUID() },
                set: { newID in update {
                    $0.penID = newID
                    $0.penColorID = nil
                    $0.penVarianteID = nil
                }}
            )) {
                Text("– Kein Stift –").tag(UUID())
                ForEach(pens) { pen in
                    Text(pen.name).tag(pen.id)
                }
            }

            if !availableColors.isEmpty {
                Picker("Farbe", selection: Binding(
                    get: { config.penColorID ?? UUID() },
                    set: { newID in update { $0.penColorID = newID } }
                )) {
                    Text("– Keine –").tag(UUID())

                    ForEach(availableColors) { color in
                        let preview = Color(color.wert) ?? .clear
                        Text("\(color.name)  \(color.wert)")
                            .tag(color.id)
                            .foregroundColor(preview)
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
                Picker("Variante", selection: Binding(
                    get: { config.penVarianteID ?? UUID() },
                    set: { newID in update { $0.penVarianteID = newID } }
                )) {
                    Text("– Keine –").tag(UUID())
                    ForEach(availableVarianten) { variant in
                        Text(variant.name).tag(variant.id)
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

            Picker("Zuordnung", selection: Binding(
                get: { config.penSVGLayerAssignment },
                set: { newValue in update { $0.penSVGLayerAssignment = newValue } }
            )) {
                Text("Ebene").tag(PenSVGLayerAssignment.toLayer)
                Text("Farbe").tag(PenSVGLayerAssignment.toColor)
            }
            .pickerStyle(.segmented)
            
            if config.penSVGLayerAssignment == .toLayer {
                TextField("Ebene", text: Binding(
                    get: { config.layer },
                    set: { newValue in update { $0.layer = newValue } }
                ))
                .textFieldStyle(.roundedBorder)
            } else {
                TextField("Farbe im SVG", text: Binding(
                    get: { config.color },
                    set: { newValue in update { $0.color = newValue } }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private func update(_ apply: (inout PenConfiguration) -> Void) {
        var configs = penConfiguration
        while configs.count <= index {
            configs.append(PenConfiguration(penSVGLayerAssignment: .toLayer, color: "", layer: "", angle: 90))
        }
        apply(&configs[index])
        penConfiguration = configs
    }
}


// Safe Array Access
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Double {
    var clean: String {
        self == floor(self) ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
