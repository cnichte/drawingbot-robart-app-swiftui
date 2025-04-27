//
//  PlotJobStore.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.

//  /Users/cnichte/Library/Containers/de.nichte.Drawingbot-RobArt/Data/Documents/svgs
// Shift+command + c - Öffnet Konsole
// ❌✅⚠️

// GenericStore.swift – mit StorageType-Unterstützung (lokal / iCloud)
import Foundation
import SwiftUI

// === GenericStoreProtocol.swift ===

// MARK: - Protokolle

protocol GenericStoreProtocol: AnyObject {
    var directoryName: String { get }
}

protocol MigratableStore: GenericStoreProtocol {
    var initialResourceName: String? { get }
    var resourceType: ResourceType { get }

    func loadItems() async
    func clearItems()
    func restoreDefaultResource() async throws
    var itemCount: Int { get }
}

// MARK: - Migration Error
enum MigrationError: Error {
    case noInitialResource
    case alreadyMigrated
}


// MARK: - GenericStore

class GenericStore<T>: ObservableObject, MigratableStore
where T: Codable & Identifiable, T.ID: Hashable {
    
    @Published var items: [T] = [] {
        didSet { refreshTrigger += 1 }
    }
    @Published var refreshTrigger: Int = 0
    
    private let fileManager = FileManager.default
    
    // MARK: - Eigenschaften
    internal var directoryName: String
    var initialResourceName: String?
    var resourceType: ResourceType
    
    @AppStorage("currentStorageType") private var currentStorageTypeRaw: String = StorageType.local.rawValue
    
    var storageType: StorageType {
        get { StorageType(rawValue: currentStorageTypeRaw) ?? .local }
        set { currentStorageTypeRaw = newValue.rawValue }
    }
    
    private var directory: URL {
        do {
            return try FileManagerService().requireDirectory(for: storageType, subdirectory: directoryName)
        } catch {
            fatalError("❌ Verzeichnis \(directoryName) konnte nicht erstellt werden: \(error)")
        }
    }
    
    var itemCount: Int {
        items.count
    }
    
    // MARK: - Initializer
    init(directoryName: String, initialResourceName: String? = nil, resourceType: ResourceType) {
        self.directoryName = directoryName
        self.initialResourceName = initialResourceName
        self.resourceType = resourceType
    }
    
    // MARK: - Laden
    func loadItems() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            var tempLoadedItems: [T] = []
            var failedFiles: [(URL, Error)] = []
            
            for file in files where file.pathExtension == "json" {
                do {
                    let item = try loadItem(from: file)
                    tempLoadedItems.append(item)
                } catch {
                    failedFiles.append((file, error))
                }
            }
            
            await MainActor.run {
                self.items = tempLoadedItems
            }
            
            if !failedFiles.isEmpty {
                print("⚠️ \(failedFiles.count) Dateien konnten nicht geladen werden:")
                for (file, error) in failedFiles {
                    print("  → \(file.lastPathComponent): \(error.localizedDescription)")
                }
            }
        } catch {
            print("❌ Fehler beim Lesen von \(directoryName): \(error.localizedDescription)")
        }
    }
    
    private func loadItem(from file: URL) throws -> T {
        print("📂 Lade Datei \(file.lastPathComponent) aus \(directoryName)")
        let data = try Data(contentsOf: file)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Speichern
    func save(item: T, fileName: String) async {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(item)
            let path = directory.appendingPathComponent("\(fileName).json")
            
            print("💾 Speichere: \(path.lastPathComponent)")
            try data.write(to: path)
            
            await MainActor.run {
                if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items[index] = item
                } else {
                    self.items.append(item)
                }
            }
        } catch {
            print("❌ Fehler beim Speichern \(fileName) in \(directoryName): \(error.localizedDescription)")
        }
    }
    
    func createNewItem(defaultItem: T, fileName: String) async -> T {
        await save(item: defaultItem, fileName: fileName)
        return defaultItem
    }
    
    func delete(item: T, fileName: String) async {
        let path = directory.appendingPathComponent("\(fileName).json")
        
        do {
            try fileManager.removeItem(at: path)
            
            await MainActor.run {
                self.items.removeAll { $0.id == item.id }
            }
            
            print("🗑️ Gelöscht: \(path.lastPathComponent)")
        } catch {
            print("❌ Fehler beim Löschen \(fileName): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Standard Restore
    
    func clearItems() {
        items.removeAll()
    }
    
    func restoreDefaultResource() async throws {
        guard let resourceName = initialResourceName else {
            throw MigrationError.noInitialResource
        }
        
        if FileManagerService.hasMigrated(resourceName: resourceName, storageType: storageType) {
            print("ℹ️ Migration für \(resourceName) wurde bereits durchgeführt.")
            return
        }
        
        try FileManagerService.migrateOnce(
            resourceName: resourceName,
            to: directoryName,
            as: T.self,
            storageType: storageType
        )
        
        await loadItems()
        print("✅ Standarddaten geladen für \(directoryName)")
    }
}
