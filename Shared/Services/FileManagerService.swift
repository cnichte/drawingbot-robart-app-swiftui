//
//  FileManagerService.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 09.04.25.
//

// Unterstützung für lokalen und iCloud-Speicher
// Codable Unterstützung
// async/await Methoden
// synchrones Lesen, Schreiben, Löschen
// listJSONFiles()
// getDirectoryURL() als public verwendbar für Debug View

// FileManagerService.swift
import Foundation

// Definiere StorageType direkt in FileManagerService.swift
enum StorageType: String, Codable {
    case local = ".local"
    case iCloud = ".iCloud"
}

class FileManagerService {
    private let fileManager = FileManager.default
    private let settingsSubdirectory = "settings"

    // MARK: - Get Directory URL
    func getDirectoryURL(for type: StorageType) -> URL? {
        let base: URL? = {
            switch type {
            case .local:
                return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            case .iCloud:
                return fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
            }
        }()

        return base?.appendingPathComponent(settingsSubdirectory)
    }

    // MARK: - Sync Methods
    func writeSync<T: Codable>(fileName: String, object: T, to storage: StorageType) throws {
        guard let dirURL = getDirectoryURL(for: storage) else {
            throw NSError(domain: "Directory not found", code: 1)
        }
        let fileURL = dirURL.appendingPathComponent(fileName)
        let data = try JSONEncoder().encode(object)
        try data.write(to: fileURL, options: .atomic)
    }

    func readSync<T: Codable>(fileName: String, from storage: StorageType) throws -> T {
        guard let dirURL = getDirectoryURL(for: storage) else {
            throw NSError(domain: "Directory not found", code: 2)
        }
        let fileURL = dirURL.appendingPathComponent(fileName)
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func deleteSync(fileName: String, from storage: StorageType) throws {
        guard let dirURL = getDirectoryURL(for: storage) else {
            throw NSError(domain: "Directory not found", code: 3)
        }
        let fileURL = dirURL.appendingPathComponent(fileName)
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    // MARK: - Helper Functions
    func listJSONFiles(in storage: StorageType) throws -> [String] {
        guard let dirURL = getDirectoryURL(for: storage) else {
            throw NSError(domain: "Directory not found", code: 4)
        }
        let files = try fileManager.contentsOfDirectory(atPath: dirURL.path)
        return files.filter { $0.hasSuffix(".json") }
    }

    // MARK: - One-time Migration
    static func migrateOnce<T: Codable & Identifiable>(
        resourceName: String,
        to directoryName: String,
        as type: T.Type // ← Wichtig: dieser Parameter stellt den Bezug her
    ) throws {
        // Prüfen, ob Migration bereits erfolgt ist
        let migrationKey = "migrated_\(resourceName)"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }

        // JSON-Datei aus Ressourcen laden
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw NSError(domain: "Resource \(resourceName).json nicht gefunden", code: 1)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let items = try decoder.decode([T].self, from: data)

        let fileManager = FileManager.default
        let service = FileManagerService()

        guard let targetDir = service.getDirectoryURL(for: .local)?.appendingPathComponent(directoryName) else {
            throw NSError(domain: "Zielverzeichnis nicht gefunden", code: 2)
        }

        if !fileManager.fileExists(atPath: targetDir.path) {
            try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
        }

        let encoder = JSONEncoder()
        for item in items {
            let fileURL = targetDir.appendingPathComponent("\(item.id).json")
            let itemData = try encoder.encode(item)
            try itemData.write(to: fileURL)
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
    }
}
