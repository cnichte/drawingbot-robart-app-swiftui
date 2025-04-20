//
//  ProjectListView.swift
//  Robart
//
//  Created by Carsten Nichte on 20.04.25.
//
import SwiftUI

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
