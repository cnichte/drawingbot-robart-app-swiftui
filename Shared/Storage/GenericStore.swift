//
//  PlotJobStore.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.

//  /Users/cnichte/Library/Containers/de.nichte.Drawingbot-RobArt/Data/Documents/svgs
// Shift+command + c - Öffnet Konsole

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

protocol ReloadableStore {
    func loadItems() async
}

extension Array where Element: Identifiable {
    mutating func replace(_ element: Element) {
        if let index = firstIndex(where: { $0.id == element.id }) {
            self[index] = element
        }
    }
}

class GenericStore<T: Codable & Identifiable>: ObservableObject, ReloadableStore where T.ID: Hashable {
    @Published var items: [T] = [] {
        didSet { refreshTrigger += 1 }
    }
    @Published var refreshTrigger: Int = 0

    private let fileManager = FileManager.default
    private let directoryName: String

    @AppStorage("currentStorageType") private var currentStorageTypeRaw: String = StorageType.local.rawValue
    private var currentStorageType: StorageType {
        get { StorageType(rawValue: currentStorageTypeRaw) ?? .local }
        set { currentStorageTypeRaw = newValue.rawValue }
    }

    private var directory: URL {
        guard let dir = FileManagerService().getDirectoryURL(for: currentStorageType)?.appendingPathComponent(directoryName) else {
            fatalError("❌ Verzeichnis für \(currentStorageType) / \(directoryName) nicht gefunden")
        }
        return dir
    }

    init(directoryName: String) {
        self.directoryName = directoryName
        Task { await loadItems() }
    }

    init(directoryName: String, storageType: StorageType) {
        self.directoryName = directoryName
        self._currentStorageTypeRaw = AppStorage(wrappedValue: storageType.rawValue, "currentStorageType")
        Task { await loadItems() }
    }

    var storageType: StorageType {
        get { StorageType(rawValue: currentStorageTypeRaw) ?? .local }
        set { currentStorageTypeRaw = newValue.rawValue }
    }

    func loadItems() async {
        do {
            let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            var loadedItems: [T] = []

            for file in files where file.pathExtension == "json" {
                if let item = try? loadItem(from: file) {
                    loadedItems.append(item)
                } else {
                    print("⚠️ Ungültige Datei übersprungen: \(file.lastPathComponent)")
                }
            }

            await MainActor.run {
                self.items = loadedItems
            }

        } catch {
            print("Fehler beim Laden der Items aus \(directory): \(error)")
        }
    }

    private func loadItem(from file: URL) throws -> T {
        let data = try Data(contentsOf: file)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func save(item: T, fileName: String) async {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(item) else { return }

        let itemFilePath = directory.appendingPathComponent("\(fileName).json")
        do {
            try data.write(to: itemFilePath)
            await MainActor.run {
                if let index = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items[index] = item
                } else {
                    self.items.append(item)
                }
            }
        } catch {
            print("❌ Fehler beim Speichern: \(error)")
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
        } catch {
            print("❌ Fehler beim Löschen: \(error)")
        }
    }
}
