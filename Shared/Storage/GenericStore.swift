//
//  PlotJobStore.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.

//  /Users/cnichte/Library/Containers/de.nichte.Drawingbot-RobArt/Data/Documents/svgs
// Shift+command + c - Öffnet Konsole
// ❌✅⚠️

// GenericStore.swift
import Foundation
import SwiftUI
import Combine

// MARK: - Protokolle
protocol ReloadableStore {
    func loadItems() async
}

protocol MigratableStore: ReloadableStore {
    var directoryName: String { get }
    var resourceType: ResourceType { get }
    var initialResourceName: String? { get }
    var itemCount: Int { get }
    func clearItems()
    func restoreDefaults() async throws
}

protocol GenericStoreProtocol: AnyObject {
    var directoryName: String { get }
    var resourceType: ResourceType { get }
}

// MARK: - GenericStore
class GenericStore<T>: ObservableObject, MigratableStore, GenericStoreProtocol
where T: Codable & Identifiable, T.ID: Hashable {
    
    @Published var items: [T] = [] {
        didSet { refreshTrigger += 1 }
    }
    @Published var refreshTrigger: Int = 0
    
    var directoryName: String
    var resourceType: ResourceType
    var initialResourceName: String?
    
    @AppStorage("currentStorageType")
    private var currentStorageTypeRaw: String = StorageType.local.rawValue
    
    private let fileManager = FileManager.default
    
    private var storageType: StorageType {
        StorageType(rawValue: currentStorageTypeRaw) ?? .local
    }
    
    private var directoryURL: URL {
        guard let dir = FileManagerService.shared.directory(for: storageType, subdirectory: directoryName) else {
            fatalError("❌ Verzeichnis \(directoryName) konnte nicht ermittelt werden!")
        }
        return dir
    }
    
    // MARK: - Initializer
    init(directoryName: String, resourceType: ResourceType = .user, initialResourceName: String? = nil) {
        self.directoryName = directoryName
        self.resourceType = resourceType
        self.initialResourceName = initialResourceName
    }
    
    // MARK: - Laden
    func loadItems() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)

            var tempItems: [T] = []

            for file in files where file.pathExtension == "json" {
                    do {
                        appLog(.error, "📚 lade: \(file.lastPathComponent) in \(directoryName)")
                        let data = try Data(contentsOf: file)
                        let item = try JSONDecoder().decode(T.self, from: data)
                        tempItems.append(item)
                    } catch let decodingError as DecodingError {
                        switch decodingError {
                        case .dataCorrupted(let context):
                            appLog(.error, "⚠️ Fehler: Daten sind beschädigt: \(context.debugDescription)")
                        case .keyNotFound(let key, let context):
                            appLog(.error, "⚠️ Fehler: Schlüssel nicht gefunden: \(key), Kontext: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            appLog(.error, "⚠️ Fehler: Typ-Mismatch für \(type): \(context.debugDescription)")
                        case .valueNotFound(let value, let context):
                            appLog(.error, "⚠️ Fehler: Wert nicht gefunden für \(value): \(context.debugDescription)")
                        @unknown default:
                            appLog(.error, "⚠️ Unbekannter Decoding Fehler: \(decodingError.localizedDescription)")
                        }
                    } catch {
                        appLog(.info, "⚠️ Fehler beim Laden von \(file.lastPathComponent): \(error.localizedDescription)")
                    }
            }

            let result = tempItems
            await MainActor.run {
                self.items = result
            }
            appLog(.info, "📚 Geladen: \(items.count) Elemente in \(directoryName)")

        } catch {
            appLog(.info, "❌ Fehler beim Lesen von \(directoryName): \(error.localizedDescription)")
        }
    }
    
    var itemCount: Int {
        items.count
    }
    
    func clearItems() {
        items.removeAll()
    }
    
    // MARK: - Restore Defaults
    func restoreDefaults() async throws {
        guard let resource = initialResourceName else {
            appLog(.info, "⚠️ Kein initialResourceName für \(directoryName), überspringe Restore.")
            return
        }

        switch resourceType {
        case .system:
            try FileManagerService.shared.restoreSystemResource(
                T.self,
                resourceName: resource,
                subdirectory: directoryName,
                storageType: storageType
            )
        case .user:
            try FileManagerService.shared.copyUserResourceIfNeeded(
                T.self,
                resourceName: resource,
                subdirectory: directoryName,
                storageType: storageType
            )
        }
        
        await loadItems()
    }
    
    // MARK: - Speichern
    func save(item: T, fileName: String) async {
        do {
            let data = try JSONEncoder().encode(item)  // Achte darauf, dass nil-Werte korrekt behandelt werden
            let path = directoryURL.appendingPathComponent("\(fileName).json")
            
            // Verzeichnis existiert?
            if !fileManager.fileExists(atPath: directoryURL.path) {
                try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
                appLog(.info, "📂 Verzeichnis wurde automatisch nacherzeugt: \(directoryName)")
            }
            
            try data.write(to: path, options: [.atomic])  // <- .atomic erzwingt Trunkierung
            // .atomic schreibt zuerst in eine Temp-Datei und ersetzt danach die alte → keine Reste mehr.
            
            await MainActor.run {
                if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items[index] = item
                } else {
                    self.items.append(item)
                }
            }
            
            appLog(.info, "💾 Gespeichert: \(path.lastPathComponent)")
        } catch {
            appLog(.info, "❌ Fehler beim Speichern: \(error.localizedDescription)")
        }
    }
    
    func delete(item: T, fileName: String) async {
        let path = directoryURL.appendingPathComponent("\(fileName).json")
        
        do {
            try fileManager.removeItem(at: path)
            await MainActor.run {
                self.items.removeAll { $0.id == item.id }
            }
            appLog(.info, "🗑️ Gelöscht: \(fileName)")
        } catch {
            appLog(.info, "❌ Fehler beim Löschen: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Convenience Funktionen
    
    func createNewItem(defaultItem: T, fileName: String) async -> T {
        await save(item: defaultItem, fileName: fileName)
        return defaultItem
    }
    
}


extension GenericStore where T.ID == UUID {
    func createNewItem(defaultItem: T) async -> T {
        await save(item: defaultItem, fileName: defaultItem.id.uuidString)
        return defaultItem
    }
}
