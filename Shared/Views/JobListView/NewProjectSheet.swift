//
//  NewProjectSheet.swift
//  Robart
//
//  Created by Carsten Nichte on 16.04.25.
//

// NewProjectSheet.swift
import SwiftUI

struct NewProjectSheet: View {
    @Binding var showSheet: Bool
    @State private var name: String = ""
    @State private var description: String = ""
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    @State private var errorMessage: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Projektinformationen")) {
                    TextField("Projektname", text: $name)
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2))
                        )
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Neues Projekt")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        showSheet = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        createProject()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func createProject() {
        Task {
            do {
                let project = ProjectData(name: name, description: description)
                _ = await projectStore.createNewItem(defaultItem: project, fileName: project.id.uuidString)
                showSheet = false
            } catch {
                errorMessage = "Fehler beim Erstellen des Projekts: \(error.localizedDescription)"
            }
        }
    }
}
