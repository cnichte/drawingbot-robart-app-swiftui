//
//  AssetStores.swift
//  Robart
//
//  Created by Carsten Nichte on 24.04.25.
//

// AssetStores.swift
import Foundation

// MARK: - AssetStoreType
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

// MARK: - AssetStores
class AssetStores: ObservableObject {

    // MARK: - User-Assets
    @Published var connectionsStore: GenericStore<ConnectionData>
    @Published var machineStore: GenericStore<MachineData>
    @Published var projectStore: GenericStore<ProjectData>
    @Published var plotJobStore: GenericStore<PlotJobData>
    @Published var pensStore: GenericStore<PenData>
    @Published var paperStore: GenericStore<PaperData>

    // MARK: - Internal-Assets
    @Published var paperFormatsStore: GenericStore<PaperFormat>
    @Published var aspectRatiosStore: GenericStore<AspectRatio>
    @Published var unitsStore: GenericStore<Units>

    // MARK: - Interne Verwaltung
    internal(set) var storeList: [(key: String, store: any MigratableStore)] = []

    var allMigratableStores: [any MigratableStore] {
        storeList.map { $0.store }
    }

    var storageType: StorageType {
        didSet {
            migrateAllStores(from: oldValue, to: storageType)
            AssetStores.ensureTargetDirectoriesExist(for: storageType)
        }
    }

    // MARK: - Initialisierung
    init(initialStorage: StorageType) {
        self.storageType = initialStorage

        AssetStores.ensureTargetDirectoriesExist(for: initialStorage)

        // User-Assets
        self.connectionsStore = GenericStore(directoryName: "connections")
        self.machineStore     = GenericStore(directoryName: "machines")
        self.projectStore     = GenericStore(directoryName: "projects")
        self.plotJobStore     = GenericStore(directoryName: "jobs")
        self.pensStore        = GenericStore(directoryName: "pens")
        self.paperStore       = GenericStore(directoryName: "papers", initialResourceName: "papers")

        // Internal-Assets
        self.paperFormatsStore = GenericStore(directoryName: "paperformats", initialResourceName: "paper-formats")
        self.aspectRatiosStore = GenericStore(directoryName: "aspectratios", initialResourceName: "aspect-ratios")
        self.unitsStore        = GenericStore(directoryName: "units", initialResourceName: "units")

        // StoreList aufbauen
        storeList = [
            ("connections", connectionsStore),
            ("machines", machineStore),
            ("projects", projectStore),
            ("jobs", plotJobStore),
            ("pens", pensStore),
            ("papers", paperStore),
            ("paperformats", paperFormatsStore),
            ("aspectratios", aspectRatiosStore),
            ("units", unitsStore)
        ]

        afterInit()
    }

    private func afterInit() {
        Task {
            for store in allMigratableStores {
                await store.loadItems()
            }
        }
    }

    // MARK: - Migration & Restore

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

    func restoreDefaultResources() {
        print("🚀 Starte Restore Default Resources...")

        Task {
            for store in allMigratableStores {
                do {
                    try await store.restoreDefaultResource()
                    print("✅ Standarddaten wiederhergestellt für \(store.directoryName)")
                } catch {
                    print("⚠️ Fehler oder kein Restore nötig für \(store.directoryName): \(error.localizedDescription)")
                }
            }
        }
    }

    func resetStoreCompletely(_ store: any MigratableStore, deleteFiles: Bool = false) {
        Task {
            if deleteFiles {
                if let directory = try? FileManagerService().requireDirectory(for: storageType, subdirectory: store.directoryName) {
                    do {
                        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                        for file in files where file.pathExtension == "json" {
                            try FileManager.default.removeItem(at: file)
                        }
                        print("🗑️ Alle Dateien in \(store.directoryName) gelöscht.")
                    } catch {
                        print("❌ Fehler beim Löschen von Dateien in \(store.directoryName): \(error)")
                    }
                }
            }
            
            await store.loadItems()
            print(deleteFiles ? "🔁 Hard Reset abgeschlossen für \(store.directoryName)" : "🔁 Soft Reset abgeschlossen für \(store.directoryName)")
        }
    }
    
    func resetStoresCompletely(deleteFiles: Bool = false) {
        Task {
            if deleteFiles {
                for store in allMigratableStores {
                    if let directory = try? FileManagerService().requireDirectory(for: storageType, subdirectory: store.directoryName) {
                        do {
                            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                            for file in files where file.pathExtension == "json" {
                                try FileManager.default.removeItem(at: file)
                            }
                            print("🗑️ Alle Dateien in \(store.directoryName) gelöscht.")
                        } catch {
                            print("❌ Fehler beim Löschen von Dateien in \(store.directoryName): \(error)")
                        }
                    }
                }
            }

            for store in allMigratableStores {
                await store.loadItems()
            }

            print(deleteFiles ? "🔁 Hard Reset abgeschlossen!" : "🔁 Soft Reset abgeschlossen!")
        }
    }

    // MARK: - Utilities

    func applyInitialStorageTypeAndMigrations(using preferred: StorageType) {
        self.storageType = preferred
    }

    func deleteAllData() {
        let service = FileManagerService()
        for store in allMigratableStores {
            if let dir = service.getDirectoryURL(for: storageType)?.appendingPathComponent(store.directoryName) {
                try? FileManager.default.removeItem(at: dir)
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

    func resetStoresInMemory() {
        for store in allMigratableStores {
            store.clearItems()
        }
        print("🧹 Alle Stores im Speicher geleert.")
    }

    func printSummary() {
        print("📝 AssetStores Zusammenfassung:")
        listAllItems()
        print("🔢 Gesamtanzahl aller Einträge: \(totalItemCount())")
    }

    func listAllItems() {
        for store in allMigratableStores {
            print("📂 \(store.directoryName): \(store.itemCount) Einträge")
        }
    }

    func totalItemCount() -> Int {
        allMigratableStores.reduce(0) { $0 + $1.itemCount }
    }

    private static func ensureTargetDirectoriesExist(for type: StorageType) {
        let service = FileManagerService()
        let subdirs = ["connections", "machines", "projects", "jobs", "pens", "papers", "paperformats", "aspectratios", "units"]

        guard let baseDir = service.getDirectoryURL(for: type) else {
            print("❌ Basisverzeichnis nicht gefunden für \(type)")
            return
        }

        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: baseDir.path) {
            try? fileManager.createDirectory(at: baseDir, withIntermediateDirectories: true)
            print("📂 Basisverzeichnis erstellt: \(baseDir.path)")
        }

        for subdir in subdirs {
            let targetDir = baseDir.appendingPathComponent(subdir)
            if !fileManager.fileExists(atPath: targetDir.path) {
                try? fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
                print("📁 Subdirectory erstellt: \(targetDir.path)")
            }
        }

        // 👉 Nach dem Erstellen: initiale Daten restoren
        DispatchQueue.main.async {
            AssetStores.shared?.restoreDefaultResourcesIfNeeded()
        }
    }
}
