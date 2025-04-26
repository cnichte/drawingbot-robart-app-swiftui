//
//  AssetStores.swift
//  Robart
//
//  Created by Carsten Nichte on 24.04.25.
//

// AssetStores.swift
import Foundation

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

        self.connectionsStore = GenericStore(directoryName: "connections")
        self.machineStore     = GenericStore(directoryName: "machines")
        self.projectStore     = GenericStore(directoryName: "projects")
        self.plotJobStore     = GenericStore(directoryName: "jobs")
        self.pensStore        = GenericStore(directoryName: "pens")
        self.paperStore       = GenericStore(directoryName: "papers", initialResourceName: "papers")
        self.paperFormatsStore = GenericStore(directoryName: "paperformats", initialResourceName: "paper-formats")
        self.aspectRatiosStore = GenericStore(directoryName: "aspectratios", initialResourceName: "aspect-ratios")
        self.unitsStore        = GenericStore(directoryName: "units", initialResourceName: "units")

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
            await restoreDefaultResourcesIfNeeded()
        }
    }

    // MARK: - Restore falls Verzeichnis leer
    public func restoreDefaultResourcesIfNeeded() async {
        print("🛠 Überprüfe Standarddaten bei allen Stores...")

        for store in allMigratableStores {
            do {
                let dirURL = try FileManagerService().requireDirectory(for: storageType, subdirectory: store.directoryName)
                let files = try FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil)

                if files.filter({ $0.pathExtension == "json" }).isEmpty {
                    print("➕ Kein Inhalt in \(store.directoryName), versuche Restore...")
                    try await store.restoreDefaultResource()
                    print("✅ Standarddaten in \(store.directoryName) wiederhergestellt!")
                } else {
                    print("✅ \(store.directoryName) enthält bereits Daten, kein Restore nötig.")
                }

            } catch {
                print("⚠️ Fehler beim Überprüfen/Wiederherstellen in \(store.directoryName): \(error)")
            }
        }
    }

    // MARK: - Migration und Reset
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

    func resetStoreCompletely(_ store: any MigratableStore, deleteFiles: Bool = false) {
        Task {
            if deleteFiles {
                if let directory = try? FileManagerService().requireDirectory(for: storageType, subdirectory: store.directoryName) {
                    do {
                        let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                        for file in files where file.pathExtension == "json" {
                            try FileManager.default.removeItem(at: file)
                        }
                        print("🗑️ Dateien gelöscht in \(store.directoryName)")
                    } catch {
                        print("❌ Fehler beim Löschen in \(store.directoryName): \(error)")
                    }
                }
            }
            
            await store.loadItems()
            
            print(deleteFiles ? "🔁 Store \(store.directoryName) Hard Reset abgeschlossen!" : "🔁 Store \(store.directoryName) Soft Reset abgeschlossen!")
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
                            print("🗑️ Dateien in \(store.directoryName) gelöscht.")
                        } catch {
                            print("❌ Fehler beim Löschen in \(store.directoryName): \(error)")
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
    }

    // 📝 Zusammenfassung
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
}
