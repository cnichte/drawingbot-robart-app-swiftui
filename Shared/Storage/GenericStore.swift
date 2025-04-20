//
//  PlotJobStore.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.

//  /Users/cnichte/Library/Containers/de.nichte.Drawingbot-RobArt/Data/Documents/svgs
// Shift+command + c - Öffnet Konsole

// GenericStore.swift
import Foundation
import SwiftUI

class GenericStore<T: Codable & Identifiable>: ObservableObject where T.ID: Hashable {
    @Published var items: [T] = []
    
    private let fileManager = FileManager.default
    private let directory: URL

    init(directoryName: String) {
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.directory = documentDirectory.appendingPathComponent(directoryName)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        Task {
            await self.loadItems()
        }
    }

    // MARK: - Laden aller gültigen .json Dateien
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
            print("Fehler beim Laden der Items: \(error.localizedDescription)")
        }
    }

    private func loadItem(from file: URL) throws -> T {
        print("📂 Lade: \(file.lastPathComponent)")
        let data = try Data(contentsOf: file)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Speichern eines Items
    func save(item: T, fileName: String) async {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(item) else {
            print("❌ Fehler beim Kodieren von \(fileName)")
            return
        }

        let itemFilePath = directory.appendingPathComponent("\(fileName).json")
        print("💾 Speichere: \(itemFilePath.lastPathComponent)")

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
            print("❌ Fehler beim Speichern: \(error.localizedDescription)")
        }
    }

    // MARK: - Neuen Eintrag anlegen
    func createNewItem(defaultItem: T, fileName: String) async -> T {
        await save(item: defaultItem, fileName: fileName)
        return defaultItem
    }

    // MARK: - Löschen eines Items
    func delete(item: T, fileName: String) async {
        let path = directory.appendingPathComponent("\(fileName).json")
        print("🗑️ Lösche: \(path.lastPathComponent)")

        do {
            try fileManager.removeItem(at: path)

            await MainActor.run {
                self.items.removeAll { $0.id == item.id }
            }
        } catch {
            print("❌ Fehler beim Löschen: \(error.localizedDescription)")
        }
    }
}
