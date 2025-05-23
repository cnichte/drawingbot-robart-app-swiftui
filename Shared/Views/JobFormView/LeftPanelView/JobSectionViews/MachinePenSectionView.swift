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
                            config: model.bindingForPenSlot(at: index),
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
    }

    // MARK: - Hilfsfunktion

    @MainActor
    private func ensurePenConfiguration() async {
        guard let machine = model.machine else {
            model.job.penConfiguration = []
            return
        }

        let desiredCount = machine.penCount
        var updated = model.job.penConfiguration

        if updated.count < desiredCount {
            updated.append(contentsOf: (updated.count..<desiredCount).map { _ in
                PenConfiguration(
                    penSVGLayerAssignment: .toLayer,
                    color: "",
                    layer: "",
                    angle: 90
                )
            })
        } else if updated.count > desiredCount {
            updated = Array(updated.prefix(desiredCount))
        }

        model.job.penConfiguration = updated
    }
}

// MARK: - PenSlotView

struct PenSlotView: View {
    @Binding var config: PenConfiguration
    let pens: [PenData]

    var body: some View {
        let selectedPen = pens.first(where: { $0.id == config.penID })
        let availableColors = selectedPen?.farben ?? []
        let availableVarianten = selectedPen?.varianten ?? []

        let selectedColor = availableColors.first(where: { $0.id == config.penColorID })
        let selectedVariante = availableVarianten.first(where: { $0.id == config.penVarianteID })

        VStack(alignment: .leading, spacing: 8) {
            Text("Slot \(config.id.uuidString.prefix(4))").font(.headline)

            Picker("Stift", selection: Binding<UUID?>(
                get: { config.penID },
                set: { newID in
                    config.penID = newID
                    config.penColorID = nil
                    config.penVarianteID = nil
                }
            )) {
                Text("– Kein Stift –").tag(nil as UUID?)
                ForEach(pens) { pen in
                    Text(pen.name).tag(Optional(pen.id))
                }
            }

            if !availableColors.isEmpty {
                Picker("Farbe", selection: Binding(
                    get: { config.penColorID ?? UUID() },
                    set: { newID in config.penColorID = newID }
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
                    set: { newID in config.penVarianteID = newID }
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

            Picker("Zuordnung", selection: $config.penSVGLayerAssignment) {
                Text("Ebene").tag(PenSVGLayerAssignment.toLayer)
                Text("Farbe").tag(PenSVGLayerAssignment.toColor)
            }
            .pickerStyle(.segmented)

            if config.penSVGLayerAssignment == .toLayer {
                TextField("Ebene", text: $config.layer)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField("Farbe im SVG", text: $config.color)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
