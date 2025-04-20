//
//  PenFormView.swift
//  Robart
//
//  Created by Carsten Nichte on 20.04.25.
//

// MARK: - PenFormView.swift
import SwiftUI

struct PenFormView: View {
    @Binding var pen: PenData
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Form {
                /*
                Section(header: Text("Details")) {
                    TextField("Name", text: $pen.name)
                        .onChange(of: pen.name) { save() }
                        .platformTextFieldModifiers()

                    TextField("Farbe", text: $pen.color)
                        .onChange(of: pen.color) { save() }
                        .platformTextFieldModifiers()

                    TextField("Stärke", text: $pen.thickness)
                        .onChange(of: pen.thickness) { save() }
                        .platformTextFieldModifiers()
                        .crossPlatformDecimalKeyboard()
                }
                 */
            }
        }
        .navigationTitle("Stift bearbeiten")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Zurück", action: onBack)
            }
            #endif
        }
    }

    private func save() {
        // Speichern über ManagerView/Binding
    }
}
