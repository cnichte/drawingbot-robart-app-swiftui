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

// MARK: - Enums

enum StorageType: String, Codable {
    case local = ".local"
    case iCloud = ".iCloud"
}

enum ResourceType: String, Codable {
    case system
    case user
}

// MARK: - FileManagerService

class FileManagerService {
    
    static let shared = FileManagerService()
    private let fileManager = FileManager.default

    private init() { }

    // MARK: - Basisverzeichnis
    func baseDirectory(for storage: StorageType) -> URL? {
        switch storage {
        case .local:
            return fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        case .iCloud:
            return fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents")
        }
    }

    func directory(for storage: StorageType, subdirectory: String) -> URL? {
        baseDirectory(for: storage)?.appendingPathComponent(subdirectory)
    }

    // MARK: - Directory Management
    func ensureAllDirectoriesExist(for stores: [any MigratableStore], storageType: StorageType) async {
        guard let base = baseDirectory(for: storageType) else {
            appLog("❌ Basisverzeichnis nicht gefunden für \(storageType)")
            return
        }
        if !fileManager.fileExists(atPath: base.path) {
            try? fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        }
        for store in stores {
            let dir = base.appendingPathComponent(store.directoryName)
            if !fileManager.fileExists(atPath: dir.path) {
                try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
                appLog("📁 Verzeichnis erstellt: \(dir.lastPathComponent)")
            }
        }
    }

    func deleteDirectory(storage: StorageType, subdirectory: String) throws {
        guard let dir = directory(for: storage, subdirectory: subdirectory) else { return }
        if fileManager.fileExists(atPath: dir.path) {
            try fileManager.removeItem(at: dir)
            appLog("🗑️ Gelöscht: \(dir.lastPathComponent)")
        }
    }

    // MARK: - Ressourcen Handling

    func restoreSystemResource<T: Codable & Identifiable>(
        _ type: T.Type,
        resourceName: String,
        subdirectory: String,
        storageType: StorageType
    ) throws {
        guard let baseURL = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw NSError(domain: "Bundle resource not found: \(resourceName)", code: 1)
        }
        let data = try Data(contentsOf: baseURL)
        let decoder = JSONDecoder()
        let items = try decoder.decode([T].self, from: data)

        guard let dirURL = directory(for: storageType, subdirectory: subdirectory) else {
            throw NSError(domain: "Directory not found for restore", code: 2)
        }

        for item in items {
            let itemURL = dirURL.appendingPathComponent("\(item.id).json")
            let encoder = JSONEncoder()
            let itemData = try encoder.encode(item)
            try itemData.write(to: itemURL)
            appLog("✅ System-Item gespeichert: \(itemURL.lastPathComponent)")
        }
    }

    func copyUserResourceIfNeeded<T: Codable & Identifiable>(
        _ type: T.Type,
        resourceName: String,
        subdirectory: String,
        storageType: StorageType
    ) throws {
        let key = "migrated_\(resourceName)_\(storageType.rawValue)"
        if UserDefaults.standard.bool(forKey: key) {
            appLog("ℹ️ UserResource \(resourceName) wurde bereits kopiert.")
            return
        }

        guard let baseURL = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw NSError(domain: "Bundle resource not found: \(resourceName)", code: 3)
        }
        let data = try Data(contentsOf: baseURL)
        let decoder = JSONDecoder()
        let items = try decoder.decode([T].self, from: data)

        guard let dirURL = directory(for: storageType, subdirectory: subdirectory) else {
            throw NSError(domain: "Directory not found for user resource", code: 4)
        }

        for item in items {
            let itemURL = dirURL.appendingPathComponent("\(item.id).json")
            let encoder = JSONEncoder()
            let itemData = try encoder.encode(item)
            try itemData.write(to: itemURL)
            appLog("✅ User-Item gespeichert: \(itemURL.lastPathComponent)")
        }

        UserDefaults.standard.set(true, forKey: key)
    }

    // MARK: - Migration

    func migrateAllStores(
        from oldStorage: StorageType,
        to newStorage: StorageType,
        stores: [any MigratableStore]
    ) async throws {
        for store in stores {
            guard let oldDir = directory(for: oldStorage, subdirectory: store.directoryName),
                  let newDir = directory(for: newStorage, subdirectory: store.directoryName) else {
                continue
            }

            if !fileManager.fileExists(atPath: newDir.path) {
                try fileManager.createDirectory(at: newDir, withIntermediateDirectories: true)
            }

            let files = try fileManager.contentsOfDirectory(at: oldDir, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "json" {
                let dest = newDir.appendingPathComponent(file.lastPathComponent)
                if !fileManager.fileExists(atPath: dest.path) {
                    try fileManager.copyItem(at: file, to: dest)
                    appLog("📦 Migriert: \(file.lastPathComponent)")
                }
            }
        }
    }

    // MARK: - Debugging

    func rollbackUserResource(for resourceName: String, storageType: StorageType) {
        let key = "migrated_\(resourceName)_\(storageType.rawValue)"
        UserDefaults.standard.removeObject(forKey: key)
        appLog("🔄 Rollback Migration: \(resourceName)")
    }
}

extension FileManagerService {
    func rollbackAllKnownUserResources(for storageType: StorageType) {
        let resourceNames = ["papers", "paper-formats", "aspect-ratios", "units"]
        for name in resourceNames {
            rollbackUserResource(for: name, storageType: storageType)
        }
    }
}


// FileManagerService+SVG.swift
// Erweiterung zum Handling des "svgs"-Verzeichnisses

extension FileManagerService {
    func ensureSVGDirectoryExists(for storage: StorageType) async {
        guard let base = baseDirectory(for: storage) else { return }
        let svgDir = base.appendingPathComponent("svgs")
        if !fileExists(at: svgDir) {
            do {
                try FileManager.default.createDirectory(at: svgDir, withIntermediateDirectories: true)
                appLog("📁 SVG-Verzeichnis erstellt")
            } catch {
                appLog("❌ Fehler beim Anlegen des SVG-Verzeichnisses: \(error.localizedDescription)")
            }
        }
    }
    
    func migrateSVGDirectory(from oldStorage: StorageType, to newStorage: StorageType) throws {
        guard let oldBase = baseDirectory(for: oldStorage),
              let newBase = baseDirectory(for: newStorage) else { return }
        
        let oldDir = oldBase.appendingPathComponent("svgs")
        let newDir = newBase.appendingPathComponent("svgs")
        
        if !fileExists(at: oldDir) {
            appLog("ℹ️ Kein SVG-Ordner vorhanden in Quelle")
            return
        }
        
        if !fileExists(at: newDir) {
            try FileManager.default.createDirectory(at: newDir, withIntermediateDirectories: true)
        }
        
        let files = try FileManager.default.contentsOfDirectory(at: oldDir, includingPropertiesForKeys: nil)
        for file in files where file.pathExtension.lowercased() == "svg" {
            let destination = newDir.appendingPathComponent(file.lastPathComponent)
            if !fileExists(at: destination) {
                try FileManager.default.copyItem(at: file, to: destination)
                appLog("📄 SVG migriert: \(file.lastPathComponent)")
            }
        }
    }
    
    private func fileExists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }
}

