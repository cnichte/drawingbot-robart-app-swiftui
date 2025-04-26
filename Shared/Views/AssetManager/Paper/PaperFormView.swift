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
    @EnvironmentObject var store: GenericStore<PaperData>
    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormat>

    var body: some View {
        Form {
            Section("Details") {
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

            Section("Eigenschaften") {
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

            Section("Papierformat") {
                Picker("Papierformat", selection: Binding(
                    get: { data.paperFormat.id },
                    set: { newID in
                        if let format = paperFormatsStore.items.first(where: { $0.id == newID }) {
                            data.paperFormat = format
                            save()
                        }
                    }
                )) {
                    ForEach(paperFormatsStore.items) { format in
                        Text(format.name).tag(format.id)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .platformFormPadding()
        .navigationTitle("Papier bearbeiten")
        .onReceive(store.$refreshTrigger) { _ in
            // Kein extra Handling nötig, SwiftUI aktualisiert automatisch
        }
    }

    private func save() {
        Task {
            await store.save(item: data, fileName: data.id.uuidString)
        }
    }
}
