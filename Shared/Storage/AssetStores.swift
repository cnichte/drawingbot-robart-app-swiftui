//
//  AssetStores.swift
//  Robart
//
//  Created by Carsten Nichte on 24.04.25.
//

// AssetStores.swift
import Foundation

// MARK: - MigrationError für bessere Fehlerunterscheidung
enum MigrationError: Error {
    case noInitialResource
    case alreadyMigrated
}

enum AssetStoreType: String, CaseIterable, Identifiable {
    case connections
    case machines
    case projects
    case jobs
    case pens
    case papers
    case paperformats
    case aspectratios
    case units

    var id: String { rawValue }
}

import Foundation

class AssetStores: ObservableObject {
    // MARK: - User-Assets
    @Published var connectionsStore: GenericStore<ConnectionData>
    @Published var machineStore: GenericStore<MachineData>
    @Published var projectStore: GenericStore<ProjectData>
    @Published var plotJobStore: GenericStore<PlotJobData>
    @Published var pensStore: GenericStore<PenData>
    @Published var paperStore: GenericStore<PaperData>

    // MARK: - Internal-Assets (mit Initial-Ressourcen)
    @Published var paperFormatsStore: GenericStore<PaperFormat>
    @Published var aspectRatiosStore: GenericStore<AspectRatio>
    @Published var unitsStore: GenericStore<Units>

    // MARK: - Migration Manager
    private(set) var manager: AssetStoreManager

    var storageType: StorageType {
        didSet {
            manager.updateStorageType(to: storageType)
        }
    }

    var allStores: [any MigratableStore] {
        [
            connectionsStore,
            machineStore,
            projectStore,
            plotJobStore,
            pensStore,
            paperStore,
            paperFormatsStore,
            aspectRatiosStore,
            unitsStore
        ]
    }

    // MARK: - Initialisierung
    init(initialStorage: StorageType) {
        self.storageType = initialStorage

        // Lokale Stores anlegen
        let connectionsStore = GenericStore<ConnectionData>(directoryName: "connections")
        let machineStore     = GenericStore<MachineData>(directoryName: "machines")
        let projectStore     = GenericStore<ProjectData>(directoryName: "projects")
        let plotJobStore     = GenericStore<PlotJobData>(directoryName: "jobs")
        let pensStore        = GenericStore<PenData>(directoryName: "pens")
        let paperStore       = GenericStore<PaperData>(directoryName: "papers", initialResourceName: "papers")
        let paperFormatsStore = GenericStore<PaperFormat>(directoryName: "paperformats", initialResourceName: "paper-formats")
        let aspectRatiosStore = GenericStore<AspectRatio>(directoryName: "aspectratios", initialResourceName: "aspect-ratios")
        let unitsStore        = GenericStore<Units>(directoryName: "units", initialResourceName: "units")

        // Manager anlegen mit diesen lokalen Stores
        self.manager = AssetStoreManager(
            stores: [
                connectionsStore,
                machineStore,
                projectStore,
                plotJobStore,
                pensStore,
                paperStore,
                paperFormatsStore,
                aspectRatiosStore,
                unitsStore
            ],
            initialStorage: initialStorage
        )

        // Jetzt Zuweisung an self.xxx
        self.connectionsStore = connectionsStore
        self.machineStore     = machineStore
        self.projectStore     = projectStore
        self.plotJobStore     = plotJobStore
        self.pensStore        = pensStore
        self.paperStore       = paperStore
        self.paperFormatsStore = paperFormatsStore
        self.aspectRatiosStore = aspectRatiosStore
        self.unitsStore        = unitsStore

        afterInit()
    }

    private func afterInit() {
        Task {
            await manager.ensureDirectoriesExist()
            await manager.restoreDefaultResourcesIfNeeded()
        }
    }

    // MARK: - Utilities (nur durchreichen)

    func applyInitialStorageTypeAndMigrations(using preferred: StorageType) {
        storageType = preferred
    }

    func deleteAllData() {
        manager.deleteAllData()
    }

    func resetStoresInMemory() {
        manager.resetStoresInMemory()
    }

    func resetStoresCompletely(deleteFiles: Bool = false) {
        Task {
            await manager.resetStoresCompletely(deleteFiles: deleteFiles)
        }
    }

    func printSummary() {
        manager.printSummary()
    }
}
