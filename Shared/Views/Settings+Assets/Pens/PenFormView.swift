//
//  PenFormView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
// 

// PenFormView.swift
import SwiftUI

struct PenFormView: View {
    @Binding var data: PenData
    
    @EnvironmentObject var assetStores: AssetStores
    @EnvironmentObject var store: GenericStore<PenData>
    
    @State private var colorInput: String = ""
    @State private var varianteSearchText = ""

    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                detailsSection
                farbenSection
                variantenSection
            }
            .padding()
        }
        .navigationTitle("Stift bearbeiten")
        .onReceive(store.$refreshTrigger) { _ in }
    }

    // MARK: - Details

    private var detailsSection: some View {
        CollapsibleSection(title: "Details", systemImage: "info.circle") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Name", text: $data.name)
                    .platformTextFieldModifiers()
                    .onChange(of: data.name) { save() }

                TextEditor(text: $data.description)
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2))
                    )
                    .onChange(of: data.description) { save() }

                TextField("Hersteller", text: $data.hersteller)
                    .onChange(of: data.hersteller) { save() }

                TextField("Shoplink", text: $data.shoplink)
                    .onChange(of: data.shoplink) { save() }
            }
        }
    }

    // MARK: - Farben

    private var farbenSection: some View {
        CollapsibleSection(
            title: "Farben",
            systemImage: "paintpalette",
            toolbar: {
                HStack(spacing: 8) {
                    TextField("Suchen …", text: $colorInput)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)

                    Button(action: {
                        data.farben.append(PenColor(id: UUID(), name: "", wert: "#000000"))
                        save()
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }
        ) {
            ForEach(filteredFarben) { $color in
                HStack(spacing: 12) {
                    TextField("Name", text: $color.name)
                        .platformTextFieldModifiers()
                        .frame(minWidth: 80)
                        .onChange(of: color.name) { save() }

                    TextField("#RRGGBB", text: $color.wert)
                        .platformTextFieldModifiers()
                        .frame(width: 100)
                        .onChange(of: color.wert) { save() }

                    ColorPicker("", selection: Binding(
                        get: { Color(color.wert) ?? .black },
                        set: { newColor in
                            color.wert = newColor.toHexString()
                            save()
                        }
                    ))
                    .labelsHidden()
                    .frame(width: 44)

                    Button(role: .destructive) {
                        data.farben.removeAll { $0.id == color.id }
                        save()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Varianten
    
    private var variantenSection: some View {
        CollapsibleSection(
            title: "Varianten",
            systemImage: "square.stack.3d.down.forward",
            toolbar: {
                HStack(spacing: 8) {
                    TextField("Suchen …", text: $varianteSearchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)

                    Button(action: {
                        data.varianten.append(PenVariante(
                            id: UUID(),
                            name: "",
                            spitzeSize: .init(x: 0, y: 0),
                            spitzeUnit: .init(id: UUID(), name: "mm"),
                            reichweite: 0,
                            reichweiteUnit: .init(id: UUID(), name: "m")
                        ))
                        save()
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }
        ) {
            VStack(spacing: 8) {
                ForEach(filteredVarianten) { $variante in
                    // Lokale Bindings für Picker
                    let spitzeUnitBinding = Binding<UUID>(
                        get: { variante.spitzeUnit.id },
                        set: { newID in
                            if let selected = assetStores.unitsStore.items.first(where: { $0.id == newID }) {
                                variante.spitzeUnit = selected
                                save()
                            }
                        }
                    )
                    let reichweiteUnitBinding = Binding<UUID>(
                        get: { variante.reichweiteUnit.id },
                        set: { newID in
                            if let selected = assetStores.unitsStore.items.first(where: { $0.id == newID }) {
                                variante.reichweiteUnit = selected
                                save()
                            }
                        }
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Name", text: $variante.name)

                        HStack {
                            MF_Tools.doubleTextField(label: "Spitze X", value: $variante.spitzeSize.x)
                            MF_Tools.doubleTextField(label: "Y", value: $variante.spitzeSize.y)
                        }

                        Picker("Spitzen-Einheit", selection: spitzeUnitBinding) {
                            ForEach(assetStores.unitsStore.items) { unit in
                                Text(unit.name).tag(unit.id)
                            }
                        }
                        .pickerStyle(.menu)

                        HStack {
                            MF_Tools.doubleTextField(label: "Reichweite", value: $variante.reichweite)

                            Picker("Reichweite-Einheit", selection: reichweiteUnitBinding) {
                                ForEach(assetStores.unitsStore.items) { unit in
                                    Text(unit.name).tag(unit.id)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    .padding(8)
                    .background(ColorHelper.backgroundColor)
                    .cornerRadius(8)
                    .onChange(of: variante) { save() }
                }
                .onDelete { indices in
                    data.varianten.remove(atOffsets: indices)
                    save()
                }
            }
        }
    }

    private var filteredFarben: [Binding<PenColor>] {
        $data.farben.filter {
            colorInput.isEmpty || $0.wrappedValue.name.localizedCaseInsensitiveContains(colorInput)
        }
    }
    
    private var filteredVarianten: [Binding<PenVariante>] {
        $data.varianten.filter {
            varianteSearchText.isEmpty || $0.wrappedValue.name.localizedCaseInsensitiveContains(varianteSearchText)
        }
    }

    private func save() {
        Task {
            await store.save(item: data, fileName: data.id.uuidString)
        }
    }
}
