//
//  PaperFormView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

// PaperFormView.swift
import SwiftUI

struct PaperFormView: View {
    @Binding var data: PaperData
    @EnvironmentObject var assetStores: AssetStores

    private var isCustomFormat: Bool {
        data.paperFormat.name.lowercased() == "custom"
    }

    var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Name", text: $data.name)
                    .platformTextFieldModifiers()
                    .onChange(of: data.name) { save() }

                TextEditor(text: $data.description)
                    .frame(minHeight: 100)
                    .onChange(of: data.description) { save() }
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2))
                    )
            }

            Section(header: Text("Eigenschaften")) {
                TextField("Gewicht", text: $data.weight)
                    .platformTextFieldModifiers()
                    .onChange(of: data.weight) { save() }

                TextField("Farbe", text: $data.color)
                    .platformTextFieldModifiers()
                    .onChange(of: data.color) { save() }

                TextField("Hersteller", text: $data.hersteller)
                    .platformTextFieldModifiers()
                    .onChange(of: data.hersteller) { save() }

                TextField("Shop-Link", text: $data.shoplink)
                    .platformTextFieldModifiers()
                    .onChange(of: data.shoplink) { save() }
            }

            Section(header: Text("Papierformat")) {
                Picker(selection: Binding(
                        get: { data.paperFormat.id },
                        set: { newID in
                            if let format = assetStores.paperFormatsStore.items.first(where: { $0.id == newID }) {
                                data.paperFormat = format
                                save()
                            }
                        }
                    ), label: Text("Papierformat")) {
                        ForEach(assetStores.paperFormatsStore.items) { format in
                            Text(format.name).tag(format.id)
                        }
                    }
                .pickerStyle(.menu)

                
                if isCustomFormat {
                    VStack(alignment: .leading, spacing: 8) {
                        
                        Picker(selection: Binding(
                            get: { data.paperFormat.aspectRatio.id },
                                set: { newID in
                                    if let ar = assetStores.aspectRatiosStore.items.first(where: { $0.id == newID }) {
                                        data.paperFormat.aspectRatio = ar
                                        save()
                                    }
                                }
                            ), label: Text("Seitenverhältnis")) {
                                ForEach(assetStores.aspectRatiosStore.items) { ar in
                                    Text(ar.name).tag(ar.id)
                                }
                            }
                        .pickerStyle(.menu)
                        
                        TextField("Breite", value: $data.paperFormat.width, format: .number)
                            .platformTextFieldModifiers()
                            .crossPlatformDecimalKeyboard()
                            .onChange(of: data.paperFormat.width) { save() }

                        TextField("Höhe", value: $data.paperFormat.height, format: .number)
                            .platformTextFieldModifiers()
                            .crossPlatformDecimalKeyboard()
                            .onChange(of: data.paperFormat.height) { save() }

                        Picker("Einheit", selection: $data.paperFormat.unit) {
                            ForEach(assetStores.unitsStore.items) { unit in
                                Text(unit.name).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: data.paperFormat.unit) { save() }
                    }
                    .padding(.top, 8)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Breite: \(data.paperFormat.width, specifier: "%.1f")")
                        Text("Höhe: \(data.paperFormat.height, specifier: "%.1f")")
                        Text("Einheit: \(data.paperFormat.unit.name)")
                    }
                    .foregroundColor(.gray)
                    .padding(.top, 8)
                }
            }
        }
        .platformFormPadding()
        .navigationTitle("Papier bearbeiten")
        .onReceive(assetStores.paperStore.$refreshTrigger) { _ in
            // Automatisches Re-Rendern
        }
    }

    private func save() {
        Task {
            await assetStores.paperStore.save(item: data, fileName: data.id.uuidString)
        }
    }
}
