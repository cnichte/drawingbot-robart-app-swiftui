//
//  ProjectEditorView.swift
//  Robart
//
//  Created by Carsten Nichte on 16.04.25.
//

// TODO: RENAME ProjectManager

// ProjectEditorView.swift
import SwiftUI

// MARK: - macOS ProjectEditorView
struct ProjectEditorView: View {
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

// MARK: - ProjectListView

struct ProjectListView: View {
    let projects: [ProjectData]
    @Binding var selectedProjectID: UUID?
    var onDelete: (ProjectData) -> Void
    var onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Projekte")
                    .font(.title2.bold())
                Spacer()
                Button(action: onAdd) {
                    Label("Projekt hinzufügen", systemImage: "plus")
                }
            }
            .padding([.horizontal, .top])

            List(selection: $selectedProjectID) {
                ForEach(projects) { project in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(project.name).bold()
                            if !project.description.isEmpty {
                                Text(project.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Button(role: .destructive) {
                            onDelete(project)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .tag(project) // Jetzt wieder direkt möglich
                }
            }
        }
        .frame(minWidth: 280, maxWidth: 320)
        .background(ColorHelper.backgroundColor)
        .padding(.trailing, 8)
    }
}


// MARK: - ProjectFormView
struct ProjectFormView: View {
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    @EnvironmentObject var plotJobStore: GenericStore<PlotJobData>
    
    @Binding var project: ProjectData
    @State private var showJobPicker = false
    
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Form {
                Section(header: Text("Details")) {
                    TextField("Name", text: $project.name)
                        .onChange(of: project.name) { save() }

                    TextEditor(text: $project.description)
                        .frame(minHeight: 100)
                        .onChange(of: project.description) { save() }
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.2))
                        )
                }
            }
            Section {
                HStack(alignment: .top) {
                    Text("Jobs")
                        .frame(minWidth: 80, alignment: .leading)

                    VStack(alignment: .leading, spacing: 8) {
                        
                        
                        Button {
                            showJobPicker = true
                        } label: {
                            Label("Job zuweisen", systemImage: "plus")
                        }
                        .buttonStyleLinkIfAvailable()
                        .sheet(isPresented: $showJobPicker) {
                            JobPickerSheet(
                                allJobs: plotJobStore.items,
                                assignedJobs: project.jobs,
                                onSelect: { job in
                                    project.jobs.append(job)
                                    save()
                                    showJobPicker = false
                                },
                                onCancel: {
                                    showJobPicker = false
                                }
                            )
                        }
                        .buttonStyleLinkIfAvailable()
                        
                        
                        
                        

                        if project.jobs.isEmpty {
                            Text("Keine zugewiesen")
                                .foregroundColor(.secondary)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(project.jobs) { job in
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(job.name)
                                                .bold()
                                            if !job.description.isEmpty {
                                                Text(job.description)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        Spacer()
                                        Button(role: .destructive) {
                                            removeJob(job)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding()

                                    if job.id != project.jobs.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .background(ColorHelper.backgroundColor)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.2))
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Projekt bearbeiten")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Zurück", action: onBack)
            }
            #endif
        }
    }

    private func removeJob(_ job: PlotJobData) {
        project.jobs.removeAll { $0.id == job.id }
        save()
    }
    
    private func save() {
        Task {
            await projectStore.save(item: project, fileName: project.id.uuidString)
        }
    }
}

// MARK: - JobPickerSheet
struct JobPickerSheet: View {
    var allJobs: [PlotJobData]
    var assignedJobs: [PlotJobData]
    var onSelect: (PlotJobData) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                let assignedIDs = Set(assignedJobs.map { $0.id })
                let unassigned = allJobs.filter { !assignedIDs.contains($0.id) }

                if unassigned.isEmpty {
                    Text("Keine verfügbaren Jobs")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(unassigned) { job in
                        Button {
                            onSelect(job)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(job.name).bold()
                                if !job.description.isEmpty {
                                    Text(job.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Job zuweisen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen", action: onCancel)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
    }
}
