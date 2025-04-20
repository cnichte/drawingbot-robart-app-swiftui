//
//  ProjectEditorView.swift
//  Robart
//
//  Created by Carsten Nichte on 16.04.25.
//

// ProjectEditorView.swift
import SwiftUI

struct ProjectEditorView: View {
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    @State private var selectedProject: ProjectData? = nil

    var body: some View {
        NavigationStack {
            Group {
                if let selected = selectedProject {
                    ProjectFormView(project: selected) {
                        selectedProject = nil
                    }
                } else {
                    List(projectStore.items, id: \ .id) { project in
                        Button(action: {
                            selectedProject = project
                        }) {
                            VStack(alignment: .leading) {
                                Text(project.name).bold()
                                if !project.description.isEmpty {
                                    Text(project.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .navigationTitle("Projekte bearbeiten")
                }
            }
        }
    }
}

struct ProjectFormView: View {
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    @State var project: ProjectData
    var onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            #if os(macOS)
            Button("Zurück", action: onBack)
                .buttonStyle(.link)
                .padding(.bottom, 4)
            #endif

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

    private func save() {
        Task {
            await projectStore.save(item: project, fileName: project.id.uuidString)
        }
    }
}

