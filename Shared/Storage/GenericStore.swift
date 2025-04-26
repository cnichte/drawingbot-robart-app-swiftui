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

// MARK: - UserDefaults Helper
extension UserDefaults {
    @objc dynamic var currentStorageType: String {
        get { string(forKey: "currentStorageType") ?? StorageType.local.rawValue }
        set { set(newValue, forKey: "currentStorageType") }
    }
}

// MARK: - Hilfsmethode (optional)
extension Array where Element: Identifiable {
    mutating func replace(_ element: Element) {
        if let index = firstIndex(where: { $0.id == element.id }) {
            self[index] = element
        }
    }
}

// MARK: - Protokolle
protocol ReloadableStore {
    func loadItems() async
}

protocol MigratableStore: ReloadableStore {
    var directoryName: String { get }
    var itemCount: Int { get }
    func clearItems()
}

// MARK: - GenericStore
class GenericStore<T: Codable & Identifiable>: ObservableObject, ReloadableStore where T.ID: Hashable {
    
    @Published var items: [T] = [] {
        didSet { refreshTrigger += 1 }
    }
    @Published var refreshTrigger: Int = 0

    private let fileManager = FileManager.default
    private var directoryName: String
    private let initialResourceName: String?

    @AppStorage("currentStorageType") private var currentStorageTypeRaw: String = StorageType.local.rawValue

    private var directory: URL {
        do {
            return try FileManagerService().requireDirectory(for: storageType, subdirectory: directoryName)
        } catch {
            fatalError("❌ Verzeichnis \(directoryName) konnte nicht erstellt werden: \(error)")
        }
    }

    var storageType: StorageType {
        get { StorageType(rawValue: currentStorageTypeRaw) ?? .local }
        set { currentStorageTypeRaw = newValue.rawValue }
    }

    // MARK: - Initializer
    init(directoryName: String, initialResourceName: String? = nil) {
        self.directoryName = directoryName
        self.initialResourceName = initialResourceName
    }

    init(directoryName: String, storageType: StorageType, initialResourceName: String? = nil) {
        self.directoryName = directoryName
        self.initialResourceName = initialResourceName
        self._currentStorageTypeRaw = AppStorage(wrappedValue: storageType.rawValue, "currentStorageType")
    }

    // Muss nach Konstruktor aufgerufen werden
    func afterInit() {
        Task {
            await loadItems()
            if items.isEmpty, let resource = initialResourceName {
                do {
                    try FileManagerService.migrateOnce(resourceName: resource, to: directoryName, as: T.self)
                    await loadItems()
                } catch {
                    print("⚠️ Fehler bei einmaliger Migration von Ressource \(resource): \(error)")
                }
            }
        }
    }

    // MARK: - Laden
    func loadItems() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            var tempLoaded: [T] = []

            for file in files where file.pathExtension == "json" {
                if let item = try? loadItem(from: file) {
                    tempLoaded.append(item)
                } else {
                    print("⚠️ Ungültige Datei in \(directoryName) übersprungen: \(file.lastPathComponent)")
                }
            }

            // Übergabe an MainActor
            let safeItems = tempLoaded

            await MainActor.run {
                self.items = safeItems
            }
        } catch {
            print("❌ Fehler beim Laden der Items aus \(directoryName): \(error.localizedDescription)")
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

    // MARK: - Neuen Eintrag anlegen
    func createNewItem(defaultItem: T, fileName: String) async -> T {
        await save(item: defaultItem, fileName: fileName)
        return defaultItem
    }

    // MARK: - Löschen
    func delete(item: T, fileName: String) async {
        let path = directory.appendingPathComponent("\(fileName).json")

        do {
            try fileManager.removeItem(at: path)

            await MainActor.run {
                self.items.removeAll { $0.id == item.id }
            }

            print("🗑️ Gelöscht: \(path.lastPathComponent)")
        } catch {
            print("❌ Fehler beim Löschen \(fileName) aus \(directoryName): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Hilfsmethoden für AssetStores (optional)

    var itemCount: Int {
        items.count
    }

    func clearItems() {
        items.removeAll()
    }
}
