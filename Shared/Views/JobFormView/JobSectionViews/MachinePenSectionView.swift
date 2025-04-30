//
//  PenSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// PenSectionView.swift
import SwiftUI

struct MachinePenSectionView: View {
    @Binding var currentJob: PlotJobData
    @Binding var selectedMachine: MachineData? // Binding für die ausgewählte Maschine
    @EnvironmentObject var assetStores: AssetStores

    var body: some View {
        CollapsibleSection(
            title: "Maschine | Stifte", // Stiftkonfiguration
            systemImage: "pencil.tip",
            toolbar: { EmptyView() }
        ) {
            if let machine = selectedMachine {
                let penSlots = machine.penCount

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0..<penSlots, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Slot \(index + 1)").font(.headline)

                            Picker("Stift", selection: Binding<String>(
                                get: {
                                    currentJob.penConfiguration[safe: index]?.color ?? ""
                                },
                                set: { newValue in
                                    updatePenConfiguration(index: index) { $0.color = newValue }
                                }
                            )) {
                                Text("– Kein Stift –").tag("")
                                ForEach(assetStores.pensStore.items) { pen in
                                    Text(pen.name).tag(pen.name)
                                }
                            }
                            .pickerStyle(.menu)

                            TextField("Ebene", text: Binding<String>(
                                get: {
                                    currentJob.penConfiguration[safe: index]?.layer ?? ""
                                },
                                set: { newValue in
                                    updatePenConfiguration(index: index) { $0.layer = newValue }
                                }
                            ))
                            .textFieldStyle(.roundedBorder)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("Bitte zuerst eine Maschine auswählen.")
                    .foregroundColor(.secondary)
            }
        }
        .onChange(of: selectedMachine) { oldMachine, newMachine in
            appLog(.info, "PEN SECTION VIEW - MACHINE CHANGED: \(String(describing: newMachine?.penCount))")
            guard let newCount = newMachine?.penCount else { return }
            let currentCount = currentJob.penConfiguration.count

            if newCount > currentCount {
                // Fehlende Slots anhängen
                let newConfigs = (currentCount..<newCount).map { _ in
                    PenConfiguration(penSVGLayerAssignment: .toLayer, color: "", layer: "", angle: 90)
                }
                currentJob.penConfiguration.append(contentsOf: newConfigs)
            } else if newCount < currentCount {
                // Überschüssige Einträge entfernen
                currentJob.penConfiguration = Array(currentJob.penConfiguration.prefix(newCount))
            }
        }
    }

    /// Stellt sicher, dass der Eintrag an Index `index` in `penConfiguration` vorhanden ist und wendet `update` an.
    private func updatePenConfiguration(index: Int, update: (inout PenConfiguration) -> Void) {
        if currentJob.penConfiguration.count <= index {
            currentJob.penConfiguration += Array(repeating: PenConfiguration(
                penSVGLayerAssignment: .toLayer, color: "", layer: "", angle: 90
            ), count: index - currentJob.penConfiguration.count + 1)
        }
        update(&currentJob.penConfiguration[index])
    }
    
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
