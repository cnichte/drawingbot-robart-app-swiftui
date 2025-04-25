//
//  AssetStores.swift
//  Robart
//
//  Created by Carsten Nichte on 24.04.25.
//

// AssetStores.swift
import Foundation

protocol AutoMigratable: AnyObject {
    var allMigratableStores: [MigratableStore] { get }
}

extension AutoMigratable {
    var allMigratableStores: [MigratableStore] {
        Mirror(reflecting: self)
            .children
            .compactMap { $0.value as? MigratableStore }
    }
}

class AssetStores: ObservableObject, AutoMigratable {
    
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
            AssetStores.ensureTargetDirectoriesExist(for: storageType)
        }
    }

    init(initialStorage: StorageType) {
        self.storageType = initialStorage
        
        AssetStores.ensureTargetDirectoriesExist(for: initialStorage)
        
        connectionsStore = GenericStore(directoryName: "connections")
        machineStore     = GenericStore(directoryName: "machines")
        projectStore     = GenericStore(directoryName: "projects")
        plotJobStore     = GenericStore(directoryName: "jobs")
        pensStore        = GenericStore(directoryName: "pens")
        paperStore       = GenericStore(directoryName: "papers")
    }

    private func migrateAllStores(from old: StorageType, to new: StorageType) {
        let migrator = SettingsMigrator()

        for store in allMigratableStores {
            do {
                try migrator.migrate(from: old, to: new, subdirectory: store.directoryName, deleteOriginal: true)
            } catch {
                print("❌ Fehler bei Migration von \(store.directoryName): \(error)")
            }
        }

        Task {
            for store in allMigratableStores {
                await store.loadItems()
            }
        }
    }

    private func performOneTimeMigrations() {
        do {
            try FileManagerService.migrateOnce(
                resourceName: "paper-formats",
                to: "papers",
                as: PaperData.self
            )
        } catch {
            print("❌ Fehler bei einmaliger Migration: \(error)")
        }
    }

    private static func ensureTargetDirectoriesExist(for type: StorageType) {
        let fileManager = FileManager.default
        let service = FileManagerService()
        let subdirs = ["connections", "machines", "projects", "jobs", "pens", "papers"]

        guard let baseDir = service.getDirectoryURL(for: type) else {
            print("❌ Basisverzeichnis für \(type) konnte nicht ermittelt werden.")
            return
        }

        if !fileManager.fileExists(atPath: baseDir.path) {
            do {
                try fileManager.createDirectory(at: baseDir, withIntermediateDirectories: true)
                print("📂 Basisverzeichnis erstellt: \(baseDir.path)")
            } catch {
                print("❌ Fehler beim Erstellen des Basisverzeichnisses: \(error.localizedDescription)")
            }
        }

        for subdir in subdirs {
            let targetDir = baseDir.appendingPathComponent(subdir)
            if !fileManager.fileExists(atPath: targetDir.path) {
                do {
                    try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
                    print("📁 Subdirectory erstellt: \(targetDir.path)")
                } catch {
                    print("❌ Fehler beim Erstellen des Subdirectorys \(subdir): \(error.localizedDescription)")
                }
            }
        }
    }

    func applyInitialStorageTypeAndMigrations(using preferred: StorageType) {
        self.storageType = preferred
    }

    func deleteAllData() {
        let service = FileManagerService()

        for store in allMigratableStores {
            if let dirURL = service.getDirectoryURL(for: storageType)?.appendingPathComponent(store.directoryName) {
                try? FileManager.default.removeItem(at: dirURL)
            }
        }
    }

    func reinitializeStores() {
        Task {
            for store in allMigratableStores {
                await store.loadItems()
            }
        }
    }
}
