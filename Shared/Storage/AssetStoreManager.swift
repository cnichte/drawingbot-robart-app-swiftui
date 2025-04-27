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
    
    // MARK: - Initialization
    
    func initialize() async {
        print("🚀 Initialisiere AssetStores...")
        await createDirectories()
        await restoreSystemDefaultsIfNeeded()
        await copyUserDefaultsIfNeeded()
    }
    
    // MARK: - Create Directories
    
    private func createDirectories() async {
        let service = FileManagerService()
        
        guard let baseDir = service.getDirectoryURL(for: storageType) else {
            print("❌ Basisverzeichnis konnte nicht ermittelt werden für \(storageType)")
            return
        }
        
        if !FileManager.default.fileExists(atPath: baseDir.path) {
            do {
                try FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
                print("📂 Basisverzeichnis erstellt: \(baseDir.path)")
            } catch {
                print("❌ Fehler beim Erstellen des Basisverzeichnisses: \(error)")
            }
        }
        
        for store in stores {
            let dir = baseDir.appendingPathComponent(store.directoryName)
            if !FileManager.default.fileExists(atPath: dir.path) {
                do {
                    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                    print("📁 Subdirectory erstellt: \(dir.path)")
                } catch {
                    print("❌ Fehler beim Erstellen von \(store.directoryName): \(error)")
                }
            }
        }
    }
    
    // MARK: - Restore System Defaults (wiederherstellbare Ressourcen)
    
    private func restoreSystemDefaultsIfNeeded() async {
        print("🛠 Überprüfe System-Ressourcen...")
        for store in stores {
            guard let genericStore = store as? GenericStoreProtocol else { continue }
            if genericStore.resourceType == .system {
                if store.itemCount == 0 {
                    do {
                        try await store.restoreDefaultResource()
                        print("✅ System-Ressource wiederhergestellt: \(store.directoryName)")
                    } catch {
                        print("⚠️ Fehler beim Wiederherstellen von \(store.directoryName): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Copy User Defaults (nur beim ersten Mal)
    
    private func copyUserDefaultsIfNeeded() async {
        print("🛠 Überprüfe User-Ressourcen...")
        for store in stores {
            guard let genericStore = store as? GenericStoreProtocol else { continue }
            if genericStore.resourceType == .user {
                if store.itemCount == 0 {
                    do {
                        try await store.restoreDefaultResource()
                        print("✅ User-Resource kopiert: \(store.directoryName)")
                    } catch {
                        print("⚠️ Fehler beim Kopieren von \(store.directoryName): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Backup (optional)
    
    func backupAll() async {
        print("💾 Backup aller Stores (TODO)")
        // TODO: Backup-Funktion implementieren falls sinnvoll
    }
    
    // MARK: - Migration (zwischen Local und iCloud)
    
    func migrate(to newStorageType: StorageType) async {
        print("🔄 Migration gestartet: \(storageType) → \(newStorageType)")
        
        let migrator = SettingsMigrator()
        
        for store in stores {
            do {
                try migrator.migrate(
                    from: storageType,
                    to: newStorageType,
                    subdirectory: store.directoryName,
                    deleteOriginal: false
                )
            } catch {
                print("❌ Fehler bei Migration \(store.directoryName): \(error)")
            }
        }
        
        self.storageType = newStorageType
    }
    
    // MARK: - Reset
    
    func resetAllData(deleteFiles: Bool = false) async {
        if deleteFiles {
            deleteAllFiles()
        }
        
        for store in stores {
            await store.loadItems()
        }
        
        print(deleteFiles ? "🔁 Hard Reset abgeschlossen!" : "🔁 Soft Reset abgeschlossen!")
    }
    
    private func deleteAllFiles() {
        print("🗑️ Lösche alle Asset-Daten...")
        let service = FileManagerService()
        
        for store in stores {
            if let baseDir = service.getDirectoryURL(for: storageType) {
                let dir = baseDir.appendingPathComponent(store.directoryName)
                try? FileManager.default.removeItem(at: dir)
            }
        }
    }
}
