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
#if os(macOS)
import AppKit
#endif

struct JobListView: View {
    @Binding var goToStep: Int
    @Binding var selectedJob: PlotJobData
    
    @EnvironmentObject var jobStore: GenericStore<PlotJobData>
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    
    @EnvironmentObject var machineStore: GenericStore<MachineData>
    @EnvironmentObject var connectionsStore: GenericStore<ConnectionData>
    
    @EnvironmentObject var pensStore: GenericStore<PenData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>

    
    @State private var isCopyMode = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    toolbar
                    unassignedSection
                    projectSections
                }
                .padding()
            }
            .navigationTitle("Jobs")
        }
    }

    private var toolbar: some View {
        HStack(spacing: 16) {
            Button("Neuer Job") {
                Task {
                    // Neuer Job wird sofort im Dateisystem gespeichert
                    let job = PlotJobData(name: "Neuer Job", paperSize: PaperSize(name: "A4", width: 210, height: 297, orientation: 0, note: ""))
                    let newJob = await jobStore.createNewItem(defaultItem: job, fileName: job.id.uuidString)
                    selectedJob = newJob // Wählt den neuen Job aus
                    goToStep = 2
                }
            }
            #if os(macOS)

            Button("Assets") {
                
                WindowManager.shared.openTabbedWindow(
                    id: .assetManager,
                    title: "Asset-Manager",
                    tabs: [
                        TabbedViewConfig( // TODO: Generic View überall benutzen!
                            title: "Connection",
                            view: ItemManagerView<ConnectionData, ConnectionFormView>(
                                title: "Connection",
                                createItem: { ConnectionData(name: "Neue Connection") },
                                buildForm: { binding in
                                    ConnectionFormView(data: binding)
                                }
                            ),
                            environmentObjects: [
                                EnvironmentObjectModifier(object: connectionsStore)
                            ]
                        ),
                        TabbedViewConfig( // TODO: Generic View überall benutzen!
                            title: "Maschine",
                            view: ItemManagerView<MachineData, MachineFormView>(
                                title: "Maschine",
                                createItem: { MachineData(name: "Neue Maschine") },
                                buildForm: { binding in
                                    MachineFormView(data: binding)
                                }
                            ),
                            environmentObjects: [
                                EnvironmentObjectModifier(object: machineStore)
                            ]
                        ),
                        TabbedViewConfig(
                            title: "Projekte",
                            view: ProjectManagerView(),
                            environmentObjects: [
                                EnvironmentObjectModifier(object: projectStore),
                                EnvironmentObjectModifier(object: jobStore)
                            ]
                        ),
                        TabbedViewConfig( // TODO: Generic View überall benutzen!
                            title: "Stifte",
                            view: ItemManagerView<PenData, PenFormView>(
                                title: "Stifte",
                                createItem: { PenData(name: "Neuer Stift") },
                                buildForm: { binding in
                                    PenFormView(data: binding)
                                }
                            ),
                            environmentObjects: [
                                EnvironmentObjectModifier(object: pensStore)
                            ]
                        ),
                        TabbedViewConfig( // TODO: Generic View überall benutzen!
                            title: "Papier",
                            view: ItemManagerView<PaperData, PaperFormView>(
                                title: "Papier",
                                createItem: { PaperData(name: "Neues Papier") },
                                buildForm: { binding in
                                    PaperFormView(data: binding)
                                }
                            ),
                            environmentObjects: [
                                EnvironmentObjectModifier(object: paperStore)
                            ]
                        ),
                        
                    ]
                )
            }
            .buttonStyle(.borderedProminent)
            
            // https://developer.apple.com/videos/play/wwdc2022/10001
            // Push Transition: drill into detail / hierarchie / modal / präsentiert von von rechts nach links /
            // Modal presentation:  / multi-step / präsentiert von unten
            // + action sheet
    
            #else
            Button("📁 Projekte") {
                showProjectManager = true
            }
            .buttonStyle(.borderedProminent)
            .sheet(isPresented: $showProjectManager) {
                ProjectManagerView()
            }
            #endif

            Toggle("D&D Copy", isOn: $isCopyMode)
                .toggleStyle(.switch)

            // Suchfeld
            TextField("Suchen …", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 400)
                .padding(.top, 4)
            
            Spacer()
        }
    }

    @State private var showProjectManager = false

    private var projectSections: some View {
        
        let filteredProjects = projectStore.items.filter {
               searchText.isEmpty ||
               $0.name.localizedCaseInsensitiveContains(searchText) ||
               $0.jobs.contains(where: {
                   $0.name.localizedCaseInsensitiveContains(searchText) ||
                   $0.description.localizedCaseInsensitiveContains(searchText)
               })
           }
        
        return ForEach(filteredProjects) { project in
            ProjectSectionView(
                project: project,
                onDrop: { droppedItems, _ in
                    handleDrop(into: project, with: droppedItems)
                },
                onJobSelected: { job in
                    selectedJob = job
                    goToStep = job.isActive ? 4 : 2
                    #if os(macOS)
                    WindowManager.shared.openWithEnvironmentObjects(
                        JobDetailView(job: job),
                        id: .jobDetail,
                        title: "Job-Details",
                        width: 900,
                        height: 600,
                        environmentObjects: [
                            EnvironmentObjectModifier(object: projectStore),
                            EnvironmentObjectModifier(object: jobStore)
                        ]
                    )
                    #endif
                },
                onDeleteJob: { job in
                    Task {
                        await jobStore.delete(item: job, fileName: job.id.uuidString)
                    }
                }
            )
        }
    }

    private var unassignedSection: some View {
        let assignedIDs = Set(projectStore.items.flatMap { $0.jobs.map { $0.id } })
        let unassignedJobs = jobStore.items.filter { !assignedIDs.contains($0.id) }
            .filter {
                searchText.isEmpty ||
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        
        return UnassignedSectionView(
            title: "Jobs ohne Projekt",
            jobs: unassignedJobs,
            onDrop: { droppedItems, _ in
                handleUnassign(jobs: droppedItems)
            },
            onJobSelected: { job in
                selectedJob = job
                goToStep = job.isActive ? 4 : 2
                #if os(macOS)
                WindowManager.shared.openWithEnvironmentObjects(
                    JobDetailView(job: job),
                    id: .jobDetail,
                    title: "Job-Details",
                    width: 900,
                    height: 600,
                    environmentObjects: [
                        EnvironmentObjectModifier(object: projectStore),
                        EnvironmentObjectModifier(object: jobStore)
                    ]
                )
                #endif
            },
            onDeleteJob: { job in
                Task {
                    await jobStore.delete(item: job, fileName: job.id.uuidString)
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

struct JobDetailView: View {
    let job: PlotJobData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Job: \(job.name)").font(.title2.bold())
            Text("Beschreibung: \(job.description.isEmpty ? "-" : job.description)")
            Text("Status: \(job.isActive ? "Aktiv" : "Inaktiv")")
            Spacer()
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
}
