//
//  JobListView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.
//

// JobListView.swift
// Erweiterte JobListView mit Sheet, Projekteditor, Drag & Drop, Kopiermodus, Modifier-Key Support (macOS) und visueller Drop-Rückmeldung
// JobListView.swift – aktualisiert mit funktionierendem Drag & Drop, Copy-Modus und visuellem Feedback

// TODO: Projekte als Favoriten markieren, oder mit Farbe.
// TODO: Suche (Text)
// TODO: Job anlegen fehlt!
// TODO: Projekte bearbeiten schön machen!
// TODO: Playhead: Job starten, und anhalten.
// TODO: Delete mit Warnung und okay abfrage.
// TODO: Drag&Drop Bereich bei leerer Liste nicht bereich ausfüllend. Text: Drop a Job!

// JobListView.swift
import SwiftUI

struct JobListView: View {
    @Binding var goToStep: Int
    @Binding var selectedJob: PlotJobData
    @EnvironmentObject var store: GenericStore<PlotJobData>
    @EnvironmentObject var projectStore: GenericStore<ProjectData>

    @State private var showProjectSheet = false
    @State private var showProjectEditor = false
    @State private var isCopyMode = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    toolbar
                    projectSections
                    unassignedSection
                }
                .padding()
            }
            .sheet(isPresented: $showProjectSheet) {
                NewProjectSheet(showSheet: $showProjectSheet)
            }
            .sheet(isPresented: $showProjectEditor) {
                ProjectEditorView()
            }
            .navigationTitle("Jobs")
        }
    }

    private var toolbar: some View {
        HStack(spacing: 16) {
            Button("➕ Projekt anlegen") {
                showProjectSheet = true
            }
            .buttonStyle(.borderedProminent)

            Button("📁 Projekte bearbeiten") {
                showProjectEditor = true
            }
            .buttonStyle(.bordered)

            Toggle("🔁 Kopiermodus", isOn: $isCopyMode)
                .toggleStyle(.switch)

            Spacer()
        }
    }

    private var projectSections: some View {
        ForEach(projectStore.items) { project in
            ProjectSectionView(
                project: project,
                onDrop: { droppedItems, _ in
                    handleDrop(into: project, with: droppedItems)
                },
                onJobSelected: { job in
                    selectedJob = job
                    goToStep = job.isActive ? 4 : 2
                },
                onDeleteJob: { job in
                    Task {
                        await store.delete(item: job, fileName: job.id.uuidString)
                    }
                }
            )
        }
    }

    private var unassignedSection: some View {
        let assignedIDs = Set(projectStore.items.flatMap { $0.jobs.map { $0.id } })
        let unassignedJobs = store.items.filter { !assignedIDs.contains($0.id) }

        return UnassignedSectionView(
            jobs: unassignedJobs,
            onDrop: { droppedItems, _ in
                handleUnassign(jobs: droppedItems)
            },
            onJobSelected: { job in
                selectedJob = job
                goToStep = job.isActive ? 4 : 2
            },
            onDeleteJob: { job in
                Task {
                    await store.delete(item: job, fileName: job.id.uuidString)
                }
            }
        )
    }

    private func handleDrop(into project: ProjectData, with droppedItems: [PlotJobData]) -> Bool {
        var updated = project
        var changed = false

        for job in droppedItems {
            if !isCopyMode {
                removeJobFromAllProjects(job)
            }
            if !updated.jobs.contains(where: { $0.id == job.id }) {
                updated.jobs.append(job)
                changed = true
            }
        }

        if changed {
            Task {
                await projectStore.save(item: updated, fileName: updated.id.uuidString)
            }
        }

        return true
    }

    private func handleUnassign(jobs: [PlotJobData]) -> Bool {
        if !isCopyMode {
            for job in jobs {
                removeJobFromAllProjects(job)
            }
        }
        return true
    }

    private func removeJobFromAllProjects(_ job: PlotJobData) {
        for project in projectStore.items {
            if project.jobs.contains(where: { $0.id == job.id }) {
                var updated = project
                updated.jobs.removeAll { $0.id == job.id }
                Task {
                    await projectStore.save(item: updated, fileName: updated.id.uuidString)
                }
            }
        }
    }
}
