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
        appLog(.info, "🚀 Initialisiere AssetStores...")
        
        await createDirectories()
        await FileManagerService.shared.ensureSVGDirectoryExists(for: storageType)
        
        var results: [StoreInitializationResult] = []
        
        for store in stores {
            if let genericStore = store as? GenericStoreProtocol {
                if genericStore.resourceType == .system || genericStore.resourceType == .user {
                    if store.itemCount == 0 {
                        do {
                            try await store.restoreDefaults()
                            results.append(.init(storeName: store.directoryName, action: .initialized))
                        } catch {
                            results.append(.init(storeName: store.directoryName, action: .empty))
                            appLog(.info, "⚠️ Fehler bei \(store.directoryName): \(error.localizedDescription)")
                        }
                    } else {
                        results.append(.init(storeName: store.directoryName, action: .alreadyPresent))
                    }
                } else {
                    results.append(.init(storeName: store.directoryName, action: .alreadyPresent))
                }
            }
        }
        
        await printInitializationSummary(results)
    }
    
    struct StoreInitializationResult {
        var storeName: String
        var action: InitializationAction
    }

    enum InitializationAction: String {
        case newlyCreated = "neu erstellt"
        case initialized = "neu initialisiert"
        case alreadyPresent = "vorhanden"
        case empty = "leer"
    }
    
    // MARK: - Create Directories
    
    private func createDirectories() async {
        let service = FileManagerService.shared

        guard let baseDir = service.baseDirectory(for: storageType) else {
            appLog(.info, "❌ Basisverzeichnis konnte nicht ermittelt werden für \(storageType)")
            return
        }

        if !FileManager.default.fileExists(atPath: baseDir.path) {
            do {
                try FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
                appLog(.info, "📂 Basisverzeichnis erstellt: \(baseDir.lastPathComponent)")
            } catch {
                appLog(.info, "❌ Fehler beim Erstellen des Basisverzeichnisses: \(error)")
            }
        }

        for store in stores {
            let dir = baseDir.appendingPathComponent(store.directoryName)
            if !FileManager.default.fileExists(atPath: dir.path) {
                do {
                    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                    appLog(.info, "📁 Verzeichnis erstellt: \(store.directoryName)")
                } catch {
                    appLog(.info, "❌ Fehler beim Erstellen von \(store.directoryName): \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func ensureAllStoresHaveContent() async {
        appLog(.info, "🔍 Überprüfe Inhalte der Stores...")
        var summary: [String] = []

        for store in stores {
            await store.loadItems()
            if store.itemCount == 0 {
                do {
                    try await store.restoreDefaults()
                    summary.append("✅ \(store.directoryName): neu erstellt")
                } catch {
                    summary.append("❌ \(store.directoryName): Fehler beim Wiederherstellen (\(error.localizedDescription))")
                }
            } else {
                summary.append("📦 \(store.directoryName): \(store.itemCount) Einträge gefunden")
            }
        }

        appLog(.info, "\n📋 Initialisierungszusammenfassung:\n")
        for line in summary {
            appLog(.info, "• \(line)")
        }
        appLog(.info, "\n✅ AssetStores Initialisierung abgeschlossen.")
    }
    
    // MARK: - Restore System Defaults (wiederherstellbare Ressourcen)
    
    private func restoreSystemDefaultsIfNeeded() async {
        appLog(.info, "🛠 Überprüfe System-Ressourcen...")
        for store in stores {
            guard let genericStore = store as? GenericStoreProtocol else { continue }
            if genericStore.resourceType == .system {
                if store.itemCount == 0 {
                    do {
                        try await store.restoreDefaults()
                        appLog(.info, "✅ System-Ressource wiederhergestellt: \(store.directoryName)")
                    } catch {
                        appLog(.info, "⚠️ Fehler beim Wiederherstellen von \(store.directoryName): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Copy User Defaults (nur beim ersten Mal)
    
    private func copyUserDefaultsIfNeeded() async {
        appLog(.info, "🛠 Überprüfe User-Ressourcen...")
        for store in stores {
            guard let genericStore = store as? GenericStoreProtocol else { continue }
            if genericStore.resourceType == .user {
                if store.itemCount == 0 {
                    do {
                        try await store.restoreDefaults()
                        appLog(.info, "✅ User-Resource kopiert: \(store.directoryName)")
                    } catch {
                        appLog(.info, "⚠️ Fehler beim Kopieren von \(store.directoryName): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Backup (optional)
    
    func backupAll() async {
        appLog(.info, "💾 Backup aller Stores (TODO)")
        // TODO: Backup-Funktion implementieren falls sinnvoll
    }
    
    // MARK: - Migration (zwischen Local und iCloud)
    
    func migrate(to newStorageType: StorageType) async {
        appLog(.info, "🔄 Migration gestartet: \(storageType) → \(newStorageType)")
        
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
                appLog(.info, "❌ Fehler bei Migration \(store.directoryName): \(error)")
            }
        }
        
        do {
            try FileManagerService.shared.migrateSVGDirectory(from: storageType, to: newStorageType)
            appLog(.info, "✅ SVG-Verzeichnis migriert")
        } catch {
            appLog(.info, "❌ Fehler beim Migrieren des SVG-Verzeichnisses: \(error.localizedDescription)")
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
        appLog(.info, "🗑️ Lösche alle Asset-Daten...")
        let service = FileManagerService.shared
        
        for store in stores {
            if let baseDir = service.baseDirectory(for: storageType) {
                let dir = baseDir.appendingPathComponent(store.directoryName)
                try? FileManager.default.removeItem(at: dir)
            }
        }
    }
    
    // MARK: - Reset In-Memory (nur Speicher leeren)
    func resetStoresInMemory() {
        appLog(.info, "🧹 Leere alle Stores im RAM...")
        for store in stores {
            store.clearItems()
        }
    }
    
    func restoreDefaultResourcesIfNeeded() async {
        await restoreSystemDefaultsIfNeeded()
        await copyUserDefaultsIfNeeded()
    }
    
    func printSummary() {
        appLog(.info, "📦 AssetStoreManager Zusammenfassung:")
        for store in stores {
            appLog(.info, "- \(store.directoryName): \(store.itemCount) Einträge")
        }
        let total = stores.map(\.itemCount).reduce(0, +)
        appLog(.info, "🔢 Gesamtanzahl: \(total)")
    }
    
    private func printInitializationSummary(_ results: [StoreInitializationResult]) async {
        appLog(.info, "")
        appLog(.info, "📋 Initialisierungszusammenfassung:")
        
        for result in results {
            let symbol: String
            switch result.action {
            case .newlyCreated: symbol = "✅"
            case .initialized: symbol = "✅"
            case .alreadyPresent: symbol = "➖"
            case .empty: symbol = "⚠️"
            }
            
            appLog(.info, "• \(symbol) \(result.storeName): \(result.action.rawValue)")
        }
        
        appLog(.info, "")
        appLog(.info, "✅ AssetStores Initialisierung abgeschlossen.")
    }
}
