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

class GenericStore<T: Codable>: ObservableObject {
    @Published var items: [T] = [] // Verwenden von T anstelle von PlotJob
    private let fileManager = FileManager.default
    private let directory: URL

    init(directoryName: String) {
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.directory = documentDirectory.appendingPathComponent(directoryName)

        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }

        // Asynchrones Nachladen auf dem MainActor
        Task {
            await self.loadItems()
        }
    }

    func loadItems() async {
        do {
            let itemFiles = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            var loadedItems: [T] = []

            for file in itemFiles {
                if file.pathExtension == "json", let item = try? loadItem(from: file) {
                    loadedItems.append(item)
                }
            }

            let itemsToSet = loadedItems
            await MainActor.run {
                self.items = itemsToSet
            }

        } catch {
            print("Fehler beim Laden der Items: \(error.localizedDescription)")
        }
    }
    
    func loadItem(from file: URL) throws -> T {
        let data = try Data(contentsOf: file)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
    
    func save(item: T, fileName: String) async {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(item)

        // Erstelle den Dateipfad für das Item
        let itemFilePath = directory.appendingPathComponent("\(fileName).json")

        // Speichern des Items
        do {
            try data?.write(to: itemFilePath)
            await loadItems() // Die Items nach dem Speichern erneut laden
        } catch {
            print("Fehler beim Speichern des Items: \(error.localizedDescription)")
        }
    }

    func createNewItem(defaultItem: T, fileName: String) async -> T {
        // Speichern des neuen Items
        await save(item: defaultItem, fileName: fileName)
        return defaultItem
    }

    func delete(item: T, fileName: String) async {
        let itemFilePath = directory.appendingPathComponent("\(fileName).json")
        print("🔍 Versuche zu löschen: \(itemFilePath.path)")

        do {
            try fileManager.removeItem(at: itemFilePath)
            await loadItems()
        } catch {
            print("❌ Fehler beim Löschen: \(error.localizedDescription)")
        }
    }
}
