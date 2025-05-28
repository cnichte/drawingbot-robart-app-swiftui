//
//  JobListView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.
//

// Sheet, Projekteditor, Drag & Drop, Kopiermodus, Modifier-Key Support (macOS) und visueller Drop-Rückmeldung
// Copy-Modus und visuellem Feedback

// MARK: - TODO

// TODO: Projekte als Favoriten markieren, oder mit Farbe.
// TODO: Projekte bearbeiten schön machen!
// TODO: Playhead: Job starten, und anhalten.
// TODO: Delete mit Warnung und okay Abfrage.

// TODO: Delete fehlt. Mit Warnung und Okay Abfrage.
// TODO: Job Anlegen Button fehlt auf iPhone

// TODO: In Projekten aktualisiert name & description nicht. JobFormView wird mit alten Werten geöffnet!
// Jobs ohne Projekt funktioniert einwandfrei.

// TODO: Prüfen:
// Hover-Effekt -Card vergrössert sich leicht + bekommt Schatten. (abba nich in Liste?)
// Auswahl-Highlight: Umrahmung in accentColor bei ausgewähltem Job. (sieht man nicht weil man sofort in Editor wechselt?)
// Tooltip: Komplette Description bei Mouseover sichtbar. (nicht zu sehen)
// Touch-Optimierung: Auf iOS gibts einfach nur Tap/Highlight.

// TODO: Mini-Animation bauen, wenn der Picker wechselt (z.B. ViewMode Grid → List mit leichtem Fade/Slide)?

// MARK: - JobListView

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
    @State private var dummyRefresh: Int = 0

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
            .navigationDestination(item: $selectedJob) { job in
                JobFormView(
                    currentJob: binding(for: job),
                    selectedJob: $selectedJob,
                    svgInspectorModel: SVGInspectorModel(job: job, machine: job.machineData)
                )
                .environmentObject(jobStore)
                .environmentObject(paperStore)
                .environmentObject(paperFormatsStore)
            }
        }
        .onReceive(jobStore.$refreshTrigger) { _ in
            dummyRefresh += 1 // ⛏️ löst Rebuild aus
        }
    }

    // MARK: - Main Section (Toolbar + Unassigned Jobs)

    private var menuSection: some View {
        Menubar(
            title: "Jobs",
            systemImage: "document.fill",
            toolbar: {
                HStack(spacing: 12) {
                    CustomToolbarButton(title: "New Job", icon: "text.document.fill", style: .secondary, role: nil, hasBorder: false, iconSize: .large) {
                        Task {
                            let job = JobData(name: "Neuer Job", machineData: .default, paperData: .default)
                            let newJob = await jobStore.createNewItem(defaultItem: job, fileName: job.id.uuidString)
                            selectedJob = newJob
                        }
                    }

                    CustomToolbarButton(title: "", icon: "folder.badge.plus", style: .secondary, role: nil, hasBorder: false, iconSize: .large) {
                        showProjectManager = true
                    }
                    .sheet(isPresented: $showProjectManager) {
                        ProjectManagerView()
                    }

                    Toggle("D&D Copy", isOn: $isCopyMode)
                        .toggleStyle(.switch)
                        .labelsHidden()

                    CustomToolbarPicker(
                        title: "",
                        icon: nil,
                        style: .secondary,
                        hasBorder: false,
                        iconSize: .medium,
                        selection: $viewMode
                    ) {
                        ForEach(JobListViewMode.allCases, id: \.self ) { mode in
                            Image(systemName: mode.systemImage)
                                .tag(mode)
                        }
                    }

                    TextField("Suchen …", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 250)
                }
            }
        )
    }

    // MARK: - Unassigned Section

    private var unassignedSection: some View {
        let assignedIDs = Set(projectStore.items.flatMap { $0.jobs.map { $0.id } })
        let unassignedJobs = jobStore.items.filter { !assignedIDs.contains($0.id) }
            .filter {
                searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) || $0.description.localizedCaseInsensitiveContains(searchText)
            }

        return JobListUnassignedSectionView(
            title: "Jobs ohne Projekt",
            jobs: .constant(unassignedJobs),
            selectedJobID: selectedJob?.id,
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

        return ForEach($projectStore.items) { $project in
            JobListProjectSectionView(
                project: $project,
                selectedJobID: selectedJob?.id,
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
