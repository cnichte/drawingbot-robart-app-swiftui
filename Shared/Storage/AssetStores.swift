//
//  AssetStores.swift
//  Robart
//
//  Created by Carsten Nichte on 24.04.25.
//

// AssetStores.swift
import Foundation

/// Definiert alle unterstützten Asset-Typen in der App.
enum AssetStoreType: String, CaseIterable, Identifiable {
    
    // MARK: - Alle bekannten Typen
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
    
    // MARK: - Resource Typ (System / User)

    /// Gibt zurück, ob es sich um eine System- oder User-Resource handelt
    var resourceType: ResourceType {
        switch self {
        case .connections:
            return .user
        case .machines:
            return .user
        case .projects:
            return .user
        case .jobs:
            return .user
        case .pens:
            return .user
        case .papers:
            return .user
        default:
            return .system
        }
    }
 

    /// Gibt den initialResourceName an (nur falls es einen gibt)
    var initialResourceName: String? {
        switch self {
        case .connections:
            return "connections"
        case .machines:
            return "machines"
        case .projects:
            return "projects"
        case .jobs:
            return "jobs"
        case .pens:
            return "pens"
        case .papers:
            return "papers"
            
        case .paperformats:
            return "paper-formats"
        case .aspectratios:
            return "aspect-ratios"
        case .units:
            return "units"
        default:
            return nil
        }
    }

}

// MARK: - AssetStores

class AssetStores: ObservableObject {
    
    static let shared = AssetStores(initialStorageType: .local)
    
    // MARK: - User Stores
    @Published var connectionsStore: GenericStore<ConnectionData>
    @Published var machineStore: GenericStore<MachineData>
    @Published var projectStore: GenericStore<ProjectData>
    @Published var plotJobStore: GenericStore<JobData>
    @Published var pensStore: GenericStore<PenData>
    @Published var paperStore: GenericStore<PaperData>

    // MARK: - System Stores
    @Published var paperFormatsStore: GenericStore<PaperFormatData>
    @Published var aspectRatiosStore: GenericStore<AspectRatioData>
    @Published var unitsStore: GenericStore<UnitsData>

    private(set) var storageType: StorageType
    
    lazy var manager: AssetStoreManager = AssetStoreManager(stores: self.allStores, initialStorage: self.storageType)

    
    // Alle Stores für Utility-Funktionen
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

    // MARK: - Initializer
    init(initialStorageType: StorageType) {
        self.storageType = initialStorageType 

        // User Stores
        self.connectionsStore = GenericStore(directoryName: "connections", resourceType: .user, initialResourceName: "connections")
        self.machineStore     = GenericStore(directoryName: "machines", resourceType: .user, initialResourceName: "machines")
        self.projectStore     = GenericStore(directoryName: "projects", resourceType: .user, initialResourceName: "projects")
        self.plotJobStore     = GenericStore(directoryName: "jobs", resourceType: .user)
        self.pensStore        = GenericStore(directoryName: "pens", resourceType: .user, initialResourceName: "pens")
        self.paperStore       = GenericStore(directoryName: "papers", resourceType: .user, initialResourceName: "papers")
         
        // System Stores
        self.paperFormatsStore = GenericStore(directoryName: "paperformats", resourceType: .system, initialResourceName: "paper-formats")
        self.aspectRatiosStore = GenericStore(directoryName: "aspectratios", resourceType: .system, initialResourceName: "aspect-ratios")
        self.unitsStore        = GenericStore(directoryName: "units", resourceType: .system, initialResourceName: "units")

        self.manager = AssetStoreManager(stores: allStores, initialStorage: initialStorageType)

        Task {
            await manager.initialize()  // ⬅️ NEU! statt manuell dirs und loadAllStores
        }
    }

    // MARK: - Laden
    private func loadAllStores() async {
        for store in allStores {
            await store.loadItems()
        }
    }

    // MARK: - Utilities
    func deleteAllLocalData() async {
        for store in allStores {
            try? FileManagerService.shared.deleteDirectory(storage: storageType, subdirectory: store.directoryName)
        }
    }

    func resetAllStoresInMemory() {
        for store in allStores {
            store.clearItems()
        }
    }

    func migrateTo(storageType newStorageType: StorageType) async throws {
        try await FileManagerService.shared.migrateAllStores(
            from: storageType,
            to: newStorageType,
            stores: allStores
        )
        self.storageType = newStorageType
    }
    
    func printSummary() {
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        appLog(.info, "📦 AssetStores Zusammenfassung:")
        appLog(.info, "Location: \(documentsURL)")
        for store in allStores {
            appLog(.info, "- \(store.directoryName): \(store.itemCount) Einträge")
        }
        appLog(.info, "🔢 Gesamtanzahl: \(allStores.map(\.itemCount).reduce(0, +))")
    }
}

extension AssetStores {
    func applyInitialStorageTypeAndMigrations(using preferredStorageType: StorageType) {
        Task {
            do {
                if self.storageType != preferredStorageType {
                    try await self.migrateTo(storageType: preferredStorageType)
                }
                await self.loadAllStores()
                appLog(.info, "✅ Speicherort angepasst auf \(preferredStorageType.rawValue)")
            } catch {
                appLog(.info, "❌ Fehler beim Anwenden des bevorzugten Speicherorts: \(error)")
            }
        }
    }
}

extension AssetStores {
    func updateMachineConnectionStatus(for connection: ConnectionData, isConnected: Bool) {
        for var machine in machineStore.items where machine.connection.connectionID == connection.id {
            machine.isConnected = isConnected
            Task {
                await machineStore.save(item: machine, fileName: machine.id.uuidString)
            }
        }
    }
}
