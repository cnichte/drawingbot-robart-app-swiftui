//
//  MachineFormView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

// MachineFormView.swift
import SwiftUI
struct MachineFormView: View {
    @Binding var data: MachineData
    @EnvironmentObject var store: GenericStore<MachineData>

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
        .navigationTitle("Maschine bearbeiten")
        .onReceive(store.$refreshTrigger) { _ in
            // Re-render wird automatisch ausgelöst – bei Bedarf kannst du hier z.B. loggen
            // appLog("🔄 FormView: Refresh getriggert")
        }
    }

    private func save() {
        Task {
            await store.save(item: data, fileName: data.id.uuidString)
        }
    }
}
