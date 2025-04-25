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
import Combine

extension UserDefaults {
    @objc dynamic var currentStorageType: String {
        get { string(forKey: "currentStorageType") ?? StorageType.local.rawValue }
        set { set(newValue, forKey: "currentStorageType") }
    }
}

extension Array where Element: Identifiable {
    mutating func replace(_ element: Element) {
        if let index = firstIndex(where: { $0.id == element.id }) {
            self[index] = element
        }
    }
}

protocol ReloadableStore {
    func loadItems() async
}

// ReloadableStore gibt es ja schon
protocol MigratableStore: ReloadableStore {
    var directoryName: String { get }
}

class GenericStore<T: Codable & Identifiable>: ObservableObject, MigratableStore where T.ID: Hashable {
    @Published var items: [T] = [] {
        didSet {
            refreshTrigger += 1
        }
    }
    @Published var refreshTrigger: Int = 0

    private let fileManager = FileManager.default
    private var service = FileManagerService()
    internal let directoryName: String // Name wie "settings", "papers", etc.

    @AppStorage("currentStorageType") private var currentStorageTypeRaw: String = StorageType.local.rawValue
    private var currentStorageType: StorageType {
        get { StorageType(rawValue: currentStorageTypeRaw) ?? .local }
        set { currentStorageTypeRaw = newValue.rawValue }
    }

    init(directoryName: String) {
        self.directoryName = directoryName
        Task {
            await loadItems()
        }
    }
    
    init(directoryName: String, storageType: StorageType) {
        self.directoryName = directoryName
        self._currentStorageTypeRaw = AppStorage(wrappedValue: storageType.rawValue, "currentStorageType")
        Task {
            await loadItems()
        }
    }

    // MARK: - Directory URL
    private var directory: URL {
        let service = FileManagerService()
        guard let dir = service.getDirectoryURL(for: currentStorageType) else {
            fatalError("❌ Verzeichnis für \(currentStorageType) nicht gefunden")
        }

        // Verzeichnis sicherstellen (wenn noch nicht existiert)
        if !FileManager.default.fileExists(atPath: dir.path) {
            do {
                try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                print("📁 Subdirectory erstellt: \(dir.path)")
            } catch {
                fatalError("❌ Fehler beim Erstellen von \(dir.path): \(error)")
            }
        }

        return dir
    }

    func createNewItem(defaultItem: T, fileName: String) async -> T {
        await save(item: defaultItem, fileName: fileName)
        return defaultItem
    }
    
    // MARK: - Load Items
    func loadItems() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            var loadedItems: [T] = []

            for file in files where file.pathExtension == "json" {
                if let item = try? loadItem(from: file) {
                    loadedItems.append(item)
                } else {
                    print("❌ Ungültige Datei \(file.lastPathComponent) übersprungen!")
                }
            }

            await MainActor.run {
                self.items = loadedItems
            }
        } catch {
            print("Fehler beim Laden: \(error.localizedDescription)")
        }
    }

    private func loadItem(from file: URL) throws -> T {
        let data = try Data(contentsOf: file)
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Save Item
    func save(item: T, fileName: String) async {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(item) else {
            print("Fehler beim Kodieren von \(fileName)")
            return
        }

        let fileURL = directory.appendingPathComponent("\(fileName).json")

        do {
            try data.write(to: fileURL)
            await MainActor.run {
                if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items[index] = item
                } else {
                    self.items.append(item)
                }
            }
        } catch {
            print("Fehler beim Speichern: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Item
    func delete(item: T, fileName: String) async {
        let fileURL = directory.appendingPathComponent("\(fileName).json")

        do {
            try fileManager.removeItem(at: fileURL)
            await MainActor.run {
                self.items.removeAll { $0.id == item.id }
            }
        } catch {
            print("Fehler beim Löschen: \(error.localizedDescription)")
        }
    }
}
