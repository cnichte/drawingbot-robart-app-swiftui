//
//  AssetStores.swift
//  Robart
//
//  Created by Carsten Nichte on 24.04.25.
//

// AssetStores.swift
import Foundation

class AssetStores: ObservableObject {
    @Published var connectionsStore: GenericStore<ConnectionData>
    @Published var machineStore: GenericStore<MachineData>
    @Published var projectStore: GenericStore<ProjectData>
    @Published var plotJobStore: GenericStore<PlotJobData>
    @Published var pensStore: GenericStore<PenData>
    @Published var paperStore: GenericStore<PaperData>

    var storageType: StorageType {
        didSet {
            migrateAllStores(from: oldValue, to: storageType)
            performOneTimeMigrations()
        }
    }

    init(initialStorage: StorageType) {
        self.storageType = initialStorage
        connectionsStore = .init(directoryName: "connections")
        machineStore     = .init(directoryName: "machines")
        projectStore     = .init(directoryName: "projects")
        plotJobStore     = .init(directoryName: "jobs")
        pensStore        = .init(directoryName: "pens")
        paperStore       = .init(directoryName: "papers")
    }

    func applyInitialStorageTypeAndMigrations(using newStorage: StorageType) {
        let old = storageType
        storageType = newStorage
        migrateAllStores(from: old, to: newStorage)
        performOneTimeMigrations()
    }

    private func migrateAllStores(from old: StorageType, to new: StorageType) {
        let migrator = SettingsMigrator()
        let directories: [(String, any ReloadableStore)] = [
            ("connections", connectionsStore),
            ("machines", machineStore),
            ("projects", projectStore),
            ("jobs", plotJobStore),
            ("pens", pensStore),
            ("papers", paperStore)
        ]

        for (name, store) in directories {
            do {
                try migrator.migrate(from: old, to: new, deleteOriginal: true)
            } catch {
                print("❌ Fehler bei Migration von \(name): \(error)")
            }
        }

        Task {
            await connectionsStore.loadItems()
            await machineStore.loadItems()
            await projectStore.loadItems()
            await plotJobStore.loadItems()
            await pensStore.loadItems()
            await paperStore.loadItems()
        }
    }

    private func performOneTimeMigrations() {
        do {
            try FileManagerService.migrateOnce(
                resourceName: "paper-format",
                to: "paperformats",
                as: PaperData.self
            )
        } catch {
            print("❌ Fehler bei einmaliger Migration: \(error)")
        }
    }
}
