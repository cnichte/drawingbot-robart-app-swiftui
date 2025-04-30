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
        VStack(alignment: .leading, spacing: 8) {
            Text("Slot \(index + 1)").font(.headline)

            Picker("Stift", selection: Binding<String>(
                get: {
                    penConfiguration[safe: index]?.color ?? ""
                },
                set: { newValue in
                    updatePenConfiguration { config in
                        config.color = newValue
                    }
                }
            )) {
                Text("– Kein Stift –").tag("")
                ForEach(pens) { pen in
                    Text(pen.name).tag(pen.name)
                }
            }
            .pickerStyle(.menu)

            TextField("Ebene", text: Binding<String>(
                get: {
                    penConfiguration[safe: index]?.layer ?? ""
                },
                set: { newValue in
                    updatePenConfiguration { config in
                        config.layer = newValue
                    }
                }
            ))
            .textFieldStyle(.roundedBorder)
        }
    }

    private func updatePenConfiguration(update: (inout PenConfiguration) -> Void) {
        var configs = penConfiguration
        while configs.count <= index {
            configs.append(PenConfiguration(penSVGLayerAssignment: .toLayer, color: "", layer: "", angle: 90))
        }
        update(&configs[index])
        penConfiguration = configs // Weise neuen Array zu, um Reaktivität sicherzustellen
    }
}

// Safe Array Access
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
