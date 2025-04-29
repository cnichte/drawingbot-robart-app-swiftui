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

                Picker("Farbe", selection: $data.farbe) {
                    ForEach(data.farben, id: \.self) { color in
                        Text(color)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: data.farbe) { save() }
            }
        }
    }

    // MARK: - Farben

    private var farbenSection: some View {
        CollapsibleSection(title: "Farben", systemImage: "paintpalette", toolbar: {
            HStack {
                TextField("Neue Farbe", text: $colorInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)

                Button(action: {
                    let trimmed = colorInput.trimmingCharacters(in: .whitespaces)
                    if !trimmed.isEmpty && !data.farben.contains(trimmed) {
                        data.farben.append(trimmed)
                        colorInput = ""
                        save()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
            }
        }) {
            ForEach(data.farben, id: \.self) { color in
                HStack {
                    Text(color)
                    Spacer()
                    Button(role: .destructive) {
                        data.farben.removeAll { $0 == color }
                        save()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(4)
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
                        data.variante.append(PenVariante(
                            name: "",
                            spitze: .init(x: 0, y: 0),
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
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Name", text: $variante.name)

                        HStack {
                            MF_Tools.doubleTextField(label: "Spitze X", value: $variante.spitze.x)
                            MF_Tools.doubleTextField(label: "Y", value: $variante.spitze.y)
                        }

                        TextField("Spitzen-Einheit", text: $variante.spitzeUnit.name)

                        HStack {
                            MF_Tools.doubleTextField(label: "Reichweite", value: $variante.reichweite)
                            TextField("Einheit", text: $variante.reichweiteUnit.name)
                        }
                    }
                    .padding(8)
                    .background(ColorHelper.backgroundColor)
                    .cornerRadius(8)
                    .onChange(of: variante) { save() }
                }
                .onDelete { indices in
                    data.variante.remove(atOffsets: indices)
                    save()
                }
            }
        }
    }

    private var filteredVarianten: [Binding<PenVariante>] {
        $data.variante.filter {
            varianteSearchText.isEmpty || $0.wrappedValue.name.localizedCaseInsensitiveContains(varianteSearchText)
        }
    }

    private func save() {
        Task {
            await store.save(item: data, fileName: data.id.uuidString)
        }
    }
}
