//
//  AssetStoreManager.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// AssetStoreManager.swift
// Verantwortlich für Migration, Backup und Restore
import Foundation

class AssetStoreManager {
    private var stores: [any MigratableStore]
    private(set) var storageType: StorageType

    init(stores: [any MigratableStore], initialStorage: StorageType) {
        self.stores = stores
        self.storageType = initialStorage
    }

    // MARK: - Directory Setup

    func ensureDirectoriesExist() async {
        let service = FileManagerService()
        guard let baseDir = service.getDirectoryURL(for: storageType) else {
            print("❌ Basisverzeichnis konnte nicht ermittelt werden für \(storageType)")
            return
        }

        let fileManager = FileManager.default

        if !fileManager.fileExists(atPath: baseDir.path) {
            do {
                try fileManager.createDirectory(at: baseDir, withIntermediateDirectories: true)
                print("📂 Basisverzeichnis erstellt: \(baseDir.path)")
            } catch {
                print("❌ Fehler beim Erstellen des Basisverzeichnisses: \(error)")
            }
        }

        for store in stores {
            let targetDir = baseDir.appendingPathComponent(store.directoryName)
            if !fileManager.fileExists(atPath: targetDir.path) {
                do {
                    try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
                    print("📁 Subdirectory erstellt: \(targetDir.path)")
                } catch {
                    print("❌ Fehler beim Erstellen von \(store.directoryName): \(error)")
                }
            }
        }
    }

    // MARK: - Restore Defaults

    func restoreDefaultResourcesIfNeeded() async {
        print("🛠 Überprüfe Standarddaten bei allen Stores...")
        for store in stores {
            if store.itemCount == 0 {
                print("➕ Kein Inhalt in \(store.directoryName), versuche Restore...")
                do {
                    try await store.restoreDefaultResource()
                    print("✅ Standarddaten in \(store.directoryName) wiederhergestellt!")
                } catch {
                    print("⚠️ Fehler beim Überprüfen/Wiederherstellen in \(store.directoryName): \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Reset / Delete

    func deleteAllData() {
        let service = FileManagerService()
        for store in stores {
            if let baseDir = service.getDirectoryURL(for: storageType) {
                let dir = baseDir.appendingPathComponent(store.directoryName)
                try? FileManager.default.removeItem(at: dir)
            }
        }
        print("🗑️ Alle Asset-Verzeichnisse gelöscht.")
    }

    func resetStoresInMemory() {
        for store in stores {
            store.clearItems()
        }
        print("🧹 Alle Stores im Speicher geleert.")
    }

    func resetStoresCompletely(deleteFiles: Bool = false) async {
        if deleteFiles {
            deleteAllData()
            await ensureDirectoriesExist()
        }

        for store in stores {
            await store.loadItems()
        }

        print(deleteFiles ? "🔁 Hard Reset abgeschlossen!" : "🔁 Soft Reset abgeschlossen!")
    }

    // MARK: - Migration

    func updateStorageType(to newType: StorageType) {
        let migrator = SettingsMigrator()
        for store in stores {
            do {
                try migrator.migrate(from: storageType, to: newType, subdirectory: store.directoryName, deleteOriginal: true)
            } catch {
                print("❌ Fehler bei Migration von \(store.directoryName): \(error)")
            }
        }
        storageType = newType
    }

    // MARK: - Debugging

    func printSummary() {
        print("📝 AssetStores Zusammenfassung:")
        for store in stores {
            print("📂 \(store.directoryName): \(store.itemCount) Einträge")
        }
        print("🔢 Gesamtanzahl aller Einträge: \(stores.reduce(0) { $0 + $1.itemCount })")
    }
}
