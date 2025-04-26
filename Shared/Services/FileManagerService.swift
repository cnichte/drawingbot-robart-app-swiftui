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

enum StorageType: String, Codable {
    case local = ".local"
    case iCloud = ".iCloud"
}

class FileManagerService {
    private let fileManager = FileManager.default
    private let settingsSubdirectory = "settings"
    
    // MARK: - Get Directory URL
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
    
    // MARK: - One-time Migration
    static func migrateOnce<T: Codable & Identifiable>(
        resourceName: String,
        to directoryName: String,
        as type: T.Type
    ) throws {
        let migrationKey = "migrated_\(resourceName)"
        
        // Prüfen, ob Migration laut UserDefaults schon gemacht wurde
        if UserDefaults.standard.bool(forKey: migrationKey) {
            print("ℹ️ Migration für \(resourceName) wurde bereits durchgeführt (laut UserDefaults).")
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

        guard let targetDir = service.getDirectoryURL(for: .local)?.appendingPathComponent(directoryName) else {
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

        // 🔥 Nach Migration sowohl Marker-File als auch UserDefaults setzen
        UserDefaults.standard.set(true, forKey: migrationKey)
        
        let migrationMarker = targetDir.deletingLastPathComponent().appendingPathComponent("\(resourceName).migrated")
        fileManager.createFile(atPath: migrationMarker.path, contents: nil)

        print("✅ Migration von \(resourceName) abgeschlossen und Marker gesetzt.")
    }

    // MARK: - Rollback Migration
    static func rollbackMigration(for resourceName: String) {
        let migrationKey = "migrated_\(resourceName)"
        UserDefaults.standard.set(false, forKey: migrationKey)
        print("🔄 Migrationseintrag zurückgesetzt: \(migrationKey)")

        // Zusätzlich: Marker-Datei löschen, falls vorhanden
        if let localDirectory = FileManagerService().getDirectoryURL(for: .local) {
            let markerFile = localDirectory.appendingPathComponent("\(resourceName).migrated")
            if FileManager.default.fileExists(atPath: markerFile.path) {
                try? FileManager.default.removeItem(at: markerFile)
                print("🗑️ Migration-Marker-Datei gelöscht: \(markerFile.lastPathComponent)")
            }
        }
    }
    
    // MARK: - Check Migration Status
    static func hasMigrated(resourceName: String, storageType: StorageType) -> Bool {
        guard let directory = FileManagerService().getDirectoryURL(for: storageType) else {
            return false
        }
        let migrationMarker = directory.appendingPathComponent("\(resourceName).migrated")
        return FileManager.default.fileExists(atPath: migrationMarker.path)
    }
}
