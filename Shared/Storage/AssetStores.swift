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
            ensureTargetDirectoriesExist(for: storageType)
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

        // FileManagerService().debugPrintICloudStatus() // <– Debugausgabe
        ensureTargetDirectoriesExist(for: initialStorage)
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

        for (name, _) in directories {
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
                to: "papers",
                as: PaperData.self
            )
        } catch {
            print("❌ Fehler bei einmaliger Migration: \(error)")
        }
    }

    private func ensureTargetDirectoriesExist(for type: StorageType) {
        let fileManager = FileManager.default
        let service = FileManagerService()
        let subdirs = ["connections", "machines", "projects", "jobs", "pens", "papers"]

        for subdir in subdirs {
            if let targetDir = service.getDirectoryURL(for: type)?.appendingPathComponent(subdir),
               !fileManager.fileExists(atPath: targetDir.path) {
                do {
                    try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
                } catch {
                    print("❌ Fehler beim Erstellen des Verzeichnisses \(targetDir): \(error)")
                }
            }
        }
    }

    func applyInitialStorageTypeAndMigrations(using preferred: StorageType) {
        self.storageType = preferred
    }

    func deleteAllData() {
        let service = FileManagerService()
        let subdirs = ["connections", "machines", "projects", "jobs", "pens", "papers"]

        for subdir in subdirs {
            if let dirURL = service.getDirectoryURL(for: storageType)?.appendingPathComponent(subdir) {
                try? FileManager.default.removeItem(at: dirURL)
            }
        }
    }

    func reinitializeStores() {
        Task {
            await connectionsStore.loadItems()
            await machineStore.loadItems()
            await projectStore.loadItems()
            await plotJobStore.loadItems()
            await pensStore.loadItems()
            await paperStore.loadItems()
        }
    }
}
