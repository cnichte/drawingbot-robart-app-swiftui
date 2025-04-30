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
// TODO: Projekte bearbeiten schön machen!
// TODO: Playhead: Job starten, und anhalten.
// TODO: Delete mit Warnung und okay abfrage.

// TODO: Prüfen:
// Hover-Effekt -Card vergrössert sich leicht + bekommt Schatten. (abba nich in Liste?)
// Auswahl-Highlight: Umrahmung in accentColor bei ausgewähltem Job. (sieht man nicht weil man sofort in Editor wechselt?)
// Tooltip: Komplette Description bei Mouseover sichtbar. (nicht zu sehen)
// Touch-Optimierung: Auf iOS gibts einfach nur Tap/Highlight.

// TODO: Mini-Animation bauen, wenn der Picker wechselt (z.B. ViewMode Grid → List mit leichtem Fade/Slide)?

// JobListView.swift
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct JobListView: View {
    @EnvironmentObject var assetStores: AssetStores
    @EnvironmentObject var jobStore: GenericStore<JobData>
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormatData>

    @State private var selectedJob: JobData? = nil
    @State private var isCopyMode = false
    @State private var searchText = ""
    @State private var showProjectManager = false
    @State private var viewMode: JobListViewMode = JobListViewMode.allCases.first ?? .list

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    menuSection
                    unassignedSection
                    projectSections
                    
                }
                .padding()
            }
            // .navigationTitle("Jobs")
            .navigationDestination(item: $selectedJob) { job in
                JobFormView(
                    currentJob: binding(for: job),
                    selectedJob: $selectedJob
                )
                .environmentObject(jobStore)
                .environmentObject(paperStore)
                .environmentObject(paperFormatsStore)
            }
        }
    }

    // MARK: - Main Section (Toolbar + Unassigned Jobs)

    private var menuSection: some View {
        Menubar(
            title: "Jobs",
            systemImage: "",
            toolbar: { // TODO: on macOS and iPad okay - on iPhone to much spacce
                HStack(spacing: 12) {
                    Button {
                        Task {
                            let job = JobData(name: "Neuer Job", paper: .default, selectedMachine: .default)
                            let newJob = await jobStore.createNewItem(defaultItem: job, fileName: job.id.uuidString)
                            selectedJob = newJob
                        }
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)

                    Toggle("D&D Copy", isOn: $isCopyMode)
                        .toggleStyle(.switch)
                        .labelsHidden()
                    
                    Picker("", selection: $viewMode) {
                        ForEach(JobListViewMode.allCases, id: \.self) { mode in
                            Label(mode.label, systemImage: mode.systemImage)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)

                    TextField("Suchen …", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 250)

                    #if !os(macOS)
                    Button("") {
                        showProjectManager = true
                    }
                    .buttonStyle(.bordered)
                    .sheet(isPresented: $showProjectManager) {
                        ProjectManagerView()
                    }
                    #endif
                }
            }
        )
    }

    // MARK: - Unassigned Section

    private var unassignedSection: some View {
        let assignedIDs = Set(projectStore.items.flatMap { $0.jobs.map { $0.id } })
        let unassignedJobs = jobStore.items.filter { !assignedIDs.contains($0.id) }
            .filter {
                searchText.isEmpty ||
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }

        return JobListUnassignedSectionView(
            title: "Jobs ohne Projekt",
            jobs: unassignedJobs,
            viewMode: viewMode,
            thumbnailProvider: { thumbnail(for: $0) },
            onDrop: { droppedItems, _ in handleUnassign(jobs: droppedItems) },
            onJobSelected: { job in selectedJob = job },
            onDeleteJob: { job in
                Task {
                    await jobStore.delete(item: job, fileName: job.id.uuidString)
                }
            }
        )
    }

    // MARK: - Project Sections

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
            JobListProjectSectionView(
                project: project,
                viewMode: viewMode,
                thumbnailProvider: { thumbnail(for: $0) },
                onDrop: { droppedItems, _ in handleDrop(into: project, with: droppedItems) },
                onJobSelected: { job in selectedJob = job },
                onDeleteJob: { job in
                    Task {
                        await jobStore.delete(item: job, fileName: job.id.uuidString)
                    }
                }
            )
        }
    }

    // MARK: - Helpers

    private func thumbnail(for job: JobData) -> Image? {
        let url = JobsDataFileManager.shared.previewFolder(for: job.id).appendingPathComponent("thumbnail.png")
        if FileManager.default.fileExists(atPath: url.path) {
            #if os(macOS)
            if let nsImage = NSImage(contentsOf: url) {
                return Image(nsImage: nsImage)
            }
            #else
            if let uiImage = UIImage(contentsOfFile: url.path) {
                return Image(uiImage: uiImage)
            }
            #endif
        }
        return nil
    }

    private func handleDrop(into project: ProjectData, with droppedItems: [JobData]) -> Bool {
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

    private func handleUnassign(jobs: [JobData]) -> Bool {
        if !isCopyMode {
            for job in jobs {
                removeJobFromAllProjects(job)
            }
        }
        return true
    }

    private func removeJobFromAllProjects(_ job: JobData) {
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

    private func binding(for job: JobData) -> Binding<JobData> {
        guard let index = jobStore.items.firstIndex(where: { $0.id == job.id }) else {
            fatalError("Job nicht gefunden")
        }
        return $jobStore.items[index]
    }
}
