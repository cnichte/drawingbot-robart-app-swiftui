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
        connectionsStore = GenericStore(directoryName: "connections")
        machineStore     = GenericStore(directoryName: "machines")
        projectStore     = GenericStore(directoryName: "projects")
        plotJobStore     = GenericStore(directoryName: "jobs")
        pensStore        = GenericStore(directoryName: "pens")
        paperStore       = GenericStore(directoryName: "papers")

        // Internal-Assets mit Resource-Datei
        paperFormatsStore = GenericStore(directoryName: "paperformats", initialResourceName: "paper-formats")
        aspectRatiosStore = GenericStore(directoryName: "aspectratios", initialResourceName: "aspect-ratios")
        
        afterInit()
    }
    
    private func afterInit() {
        Task {
            for store in allMigratableStores {
                await store.loadItems()
            }
        }
    }
    
    // MARK: - Migration
    
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
    
    private static func ensureTargetDirectoriesExist(for type: StorageType) {
        let service = FileManagerService()
        let subdirs = ["connections", "machines", "projects", "jobs", "pens", "papers", "paperformats", "aspectratios"]
        
        guard let baseDir = service.getDirectoryURL(for: type) else {
            print("❌ Basisverzeichnis für \(type) konnte nicht ermittelt werden.")
            return
        }
        
        let fileManager = FileManager.default

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
                    print("❌ Fehler beim Erstellen von \(subdir): \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Utilities

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
    
    
    // MARK: - Hilfsmethoden für Debugging und Tools

    /// Listet alle gespeicherten Objekte pro Store auf.
    func listAllItems() {
        for store in allMigratableStores {
            print("📂 \(store.directoryName): \(store.itemCount) Einträge")
        }
    }

    /// Gibt die Gesamtanzahl aller Einträge über alle Stores zurück.
    func totalItemCount() -> Int {
        allMigratableStores.reduce(into: 0) { $0 + $1.itemCount }
    }

    /// Zeigt eine kompakte Zusammenfassung an.
    func printSummary() {
        print("📝 AssetStores Zusammenfassung:")
        listAllItems()
        print("🔢 Gesamtanzahl aller Einträge: \(totalItemCount())")
    }

    /// Setzt alle Stores im Speicher zurück (löscht NICHT von der Festplatte)
    func resetStoresInMemory() {
        for store in allMigratableStores {
            store.clearItems()
        }
        print("🧹 Alle Stores im Speicher geleert.")
    }

    /// Setzt alle Stores, löscht zusätzlich alle Dateien und lädt frisch
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
    
    /// Stellt die internen Standarddaten (z.B. paperformats, aspectratios) wieder her
    func restoreDefaultResources() {
        Task {
            do {
                try FileManagerService.migrateOnce(
                    resourceName: "paper-formats",
                    to: "paperformats",
                    as: PaperFormat.self
                )
                
                try FileManagerService.migrateOnce(
                    resourceName: "aspect-ratios",
                    to: "aspectratios",
                    as: AspectRatio.self
                )

                // Nach dem Restore neu laden
                await paperFormatsStore.loadItems()
                await aspectRatiosStore.loadItems()
                
                print("✅ Standarddaten erfolgreich wiederhergestellt!")
            } catch {
                print("❌ Fehler beim Wiederherstellen der Standarddaten: \(error)")
            }
        }
    }
}
