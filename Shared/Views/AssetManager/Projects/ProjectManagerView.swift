//
//  ProjectManagerView.swift
//  Robart
//
//  Created by Carsten Nichte on 16.04.25.
//

// ProjectEditorView.swift
import SwiftUI


// MARK: - macOS ProjectEditorView is now ProjectManagerView
struct ProjectManagerView: View {
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    @State private var selectedProjectID: UUID? = nil
    @EnvironmentObject var jobStore: GenericStore<PlotJobData>
    var body: some View {
        
        NavigationStack {
            #if os(iOS)
            iOSLayout
            #else
            macOSLayout
            #endif
        }
        /*
        .onChange(of: projectStore.items) {
            if let id = selectedProjectID {
                // Prüfverzögerung einbauen – z. B. 50ms
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if !projectStore.items.contains(where: { $0.id == id }) {
                        selectedProjectID = nil
                    }
                }
            }
        }
        */
    }

    // MARK: - Binding zum echten Store-Projekt
    private var selectedProjectBinding: Binding<ProjectData>? {
        guard let id = selectedProjectID,
              let _ = projectStore.items.firstIndex(where: { $0.id == id }) else {
            // Projekt existiert nicht mehr – Auswahl zurücksetzen
            if selectedProjectID != nil {
                DispatchQueue.main.async {
                    selectedProjectID = nil
                }
            }
            return nil
        }

        return Binding<ProjectData>(
            get: {
                guard let index = projectStore.items.firstIndex(where: { $0.id == id }) else {
                    // Projekt ist (noch) nicht da – leere Fallback-Instanz, die nie gespeichert wird
                    return ProjectData(id: id, name: "", description: "")
                }
                return projectStore.items[index]
            },
            set: { newValue in
                if projectStore.items.contains(where: { $0.id == newValue.id }) {
                    Task {
                        await projectStore.save(item: newValue, fileName: newValue.id.uuidString)
                    }
                }
            }
        )
    }

    // MARK: - macOS Layout
    private var macOSLayout: some View {
        HStack(spacing: 0) {
            ProjectListView(
                projects: projectStore.items,
                selectedProjectID: $selectedProjectID,
                onDelete: confirmDeletion,
                onAdd: addNewProject
            )
            Divider()
            if let binding = selectedProjectBinding {
                ProjectFormView(project: binding, onBack: {})
                    .frame(minWidth: 500, maxWidth: .infinity)
                    .padding()
            } else {
                VStack {
                    Spacer()
                    Text("Wähle ein Projekt aus")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .navigationTitle("Projekte verwalten")
        /*
        .onChange(of: projectStore.items) {
            if let id = selectedProjectID {
                // Prüfverzögerung einbauen – z. B. 50ms
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    if !projectStore.items.contains(where: { $0.id == id }) {
                        selectedProjectID = nil
                    }
                }
            }
        }
        */
    }

    // MARK: - iOS Layout
    private var iOSLayout: some View {
        Group {
            if let binding = selectedProjectBinding {
                ProjectFormView(project: binding) {
                    selectedProjectID = nil
                }
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Projekte")
                            .font(.title2.bold())
                        Spacer()
                        Button(action: addNewProject) {
                            Label("Projekt hinzufügen", systemImage: "plus")
                        }
                    }
                    .padding([.horizontal, .top])

                    List {
                        ForEach(projectStore.items) { project in
                            HStack {
                                Button {
                                    selectedProjectID = project.id
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(project.name).bold()
                                        if !project.description.isEmpty {
                                            Text(project.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    confirmDeletion(project)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Projekte verwalten")
    }

    private func confirmDeletion(_ project: ProjectData) {
        #if os(macOS)
        let alert = NSAlert()
        alert.messageText = "Projekt löschen?"
        alert.informativeText = "Möchtest du das Projekt \"\(project.name)\" wirklich löschen?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Löschen")
        alert.addButton(withTitle: "Abbrechen")
        if alert.runModal() == .alertFirstButtonReturn {
            if selectedProjectID == project.id {
                selectedProjectID = nil
            }
            Task {
                await projectStore.delete(item: project, fileName: project.id.uuidString)
            }
        }
        #endif
    }

    private func addNewProject() {
        let newProject = ProjectData(name: "Neues Projekt", description: "")
        Task {
            _ = await projectStore.createNewItem(defaultItem: newProject, fileName: newProject.id.uuidString)

            // Aktiv warten, bis das Projekt wirklich im Store auftaucht
            while !projectStore.items.contains(where: { $0.id == newProject.id }) {
                try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
            }

            await MainActor.run {
                selectedProjectID = newProject.id
            }
        }
    }
}
