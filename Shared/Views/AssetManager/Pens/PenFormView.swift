//
//  PenFormView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

// PenFormView.swift
import SwiftUI
#if os(macOS)
struct PenFormView: View {
    @Binding var data: PenData
    @EnvironmentObject var store: GenericStore<PenData>

    var body: some View {
        Form {
            Section {
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
            } header: {
                Text("Details")
            }

            // Weitere Pen-spezifische Felder kannst du hier hinzufügen…
        }
        .platformFormPadding()
        .navigationTitle("Stift bearbeiten")
    }

    private func save() {
        Task {
            await store.save(item: data, fileName: data.id.uuidString)
        }
    }
}
#endif
