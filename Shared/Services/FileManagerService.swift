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

// FileManagerService.swift – jetzt mit Migrations-Marker im Dateisystem
import Foundation

enum StorageType: String, Codable {
    case local = ".local"
    case iCloud = ".iCloud"
}

class FileManagerService {
    private let fileManager = FileManager.default

    // MARK: - Directory Management

    func getDirectoryURL(for type: StorageType, subdirectory: String? = nil) -> URL? {
        let base: URL? = {
            switch type {
            case .local:
                return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            case .iCloud:
                return fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
            }
        }()

        guard let baseURL = base else { return nil }

        if let sub = subdirectory {
            return baseURL.appendingPathComponent(sub)
        } else {
            return baseURL
        }
    }

    func requireDirectory(for storage: StorageType, subdirectory: String) throws -> URL {
        guard let baseDir = getDirectoryURL(for: storage) else {
            throw NSError(domain: "Directory not found for \(storage)", code: 42)
        }

        let dir = baseDir.appendingPathComponent(subdirectory)

        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
            print("📁 Subdirectory erstellt: \(dir.path)")
        }

        return dir
    }

    // MARK: - Migration Handling

    static func migrateOnce<T: Codable & Identifiable>(
        resourceName: String,
        to directoryName: String,
        as type: T.Type,
        storageType: StorageType = .local
    ) throws {
        if hasMigrated(resourceName: resourceName, storageType: storageType) {
            print("ℹ️ Migration für \(resourceName) wurde bereits durchgeführt.")
            return
        }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw NSError(domain: "Resource \(resourceName).json nicht gefunden", code: 1)
        }

        let data = try Data(contentsOf: url)

        guard !data.isEmpty else {
            throw NSError(domain: "Resource \(resourceName).json ist leer", code: 2)
        }

        print("📄 Geladener Inhalt von \(resourceName).json:")
        if let contentString = String(data: data, encoding: .utf8) {
            print(contentString)
        } else {
            print("⚠️ Inhalt konnte nicht als UTF-8 gelesen werden.")
        }

        let decoder = JSONDecoder()
        let items = try decoder.decode([T].self, from: data)

        let fileManager = FileManager.default
        let service = FileManagerService()

        guard let targetDir = service.getDirectoryURL(for: storageType)?.appendingPathComponent(directoryName) else {
            throw NSError(domain: "Zielverzeichnis nicht gefunden", code: 3)
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

        markMigrated(resourceName: resourceName, storageType: storageType)
        print("✅ Migration von \(resourceName) abgeschlossen und Marker gesetzt.")
    }

    // MARK: - Migration Marker Filesystem

    static func migratedFileURL(for resourceName: String, storageType: StorageType) -> URL? {
        guard let systemDir = FileManagerService().getDirectoryURL(for: storageType, subdirectory: "system") else {
            return nil
        }
        return systemDir.appendingPathComponent("\(resourceName).migrated")
    }

    static func hasMigrated(resourceName: String, storageType: StorageType) -> Bool {
        guard let url = migratedFileURL(for: resourceName, storageType: storageType) else {
            return false
        }
        return FileManager.default.fileExists(atPath: url.path)
    }

    static func markMigrated(resourceName: String, storageType: StorageType) {
        guard let url = migratedFileURL(for: resourceName, storageType: storageType) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: url.path, contents: nil)
    }

    static func rollbackMigration(resourceName: String, storageType: StorageType) {
        guard let url = migratedFileURL(for: resourceName, storageType: storageType) else { return }
        try? FileManager.default.removeItem(at: url)
        print("🔄 Migrationseintrag zurückgesetzt: \(resourceName)")
    }

    static func rollbackAllMigrations(storageType: StorageType = .local) {
        let allResourceNames = [
            "papers",
            "paper-formats",
            "aspect-ratios",
            "units"
        ]

        for resource in allResourceNames {
            rollbackMigration(resourceName: resource, storageType: storageType)
        }
        print("🔄 Alle Migrationseinträge wurden zurückgesetzt!")
    }
}
