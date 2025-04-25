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
        
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            print("📁 Subdirectory erstellt: \(dir.path)")
        }
        
        return dir
    }
    
    // MARK: - One-time Migration
    // Im Debug-Menu oder als versteckter Button: FileManagerService.rollbackMigration(for: "paper-formats")
    static func migrateOnce<T: Codable & Identifiable>(
        resourceName: String,
        to directoryName: String,
        as type: T.Type
    ) throws {
        let migrationKey = "migrated_\(resourceName)"
        
        if UserDefaults.standard.bool(forKey: migrationKey) {
            print("ℹ️ Migration \(resourceName) wurde bereits durchgeführt. Überspringe.")
            return
        }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            print("⚠️ Resource \(resourceName).json wurde im Bundle nicht gefunden. Migration wird übersprungen.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let items = try decoder.decode([T].self, from: data)

            let fileManager = FileManager.default
            let service = FileManagerService()

            guard let targetDir = service.getDirectoryURL(for: .local)?.appendingPathComponent(directoryName) else {
                print("❌ Zielverzeichnis für Migration nicht gefunden: \(directoryName)")
                return
            }

            if !fileManager.fileExists(atPath: targetDir.path) {
                try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
                print("📁 Subdirectory erstellt: \(targetDir.path)")
            }

            let encoder = JSONEncoder()
            for item in items {
                let fileURL = targetDir.appendingPathComponent("\(item.id).json")
                let itemData = try encoder.encode(item)
                try itemData.write(to: fileURL)
                print("💾 Migriert: \(fileURL.lastPathComponent)")
            }

            UserDefaults.standard.set(true, forKey: migrationKey)
            print("✅ Migration von \(resourceName) abgeschlossen.")

        } catch {
            print("❌ Fehler bei Migration \(resourceName): \(error.localizedDescription)")
        }
    }

    // MARK: - Rollback Migration
    static func rollbackMigration(for resourceName: String) {
        let migrationKey = "migrated_\(resourceName)"
        UserDefaults.standard.set(false, forKey: migrationKey)
        print("🔄 Migrationseintrag zurückgesetzt: \(migrationKey)")
    }
}
