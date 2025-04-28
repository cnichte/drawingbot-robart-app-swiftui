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
            print("❌ Basisverzeichnis nicht gefunden für \(storageType)")
            return
        }
        if !fileManager.fileExists(atPath: base.path) {
            try? fileManager.createDirectory(at: base, withIntermediateDirectories: true)
        }
        for store in stores {
            let dir = base.appendingPathComponent(store.directoryName)
            if !fileManager.fileExists(atPath: dir.path) {
                try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
                print("📁 Verzeichnis erstellt: \(dir.lastPathComponent)")
            }
        }
    }

    func deleteDirectory(storage: StorageType, subdirectory: String) throws {
        guard let dir = directory(for: storage, subdirectory: subdirectory) else { return }
        if fileManager.fileExists(atPath: dir.path) {
            try fileManager.removeItem(at: dir)
            print("🗑️ Gelöscht: \(dir.lastPathComponent)")
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
            print("✅ System-Item gespeichert: \(itemURL.lastPathComponent)")
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
            print("ℹ️ UserResource \(resourceName) wurde bereits kopiert.")
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
            print("✅ User-Item gespeichert: \(itemURL.lastPathComponent)")
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
                    print("📦 Migriert: \(file.lastPathComponent)")
                }
            }
        }
    }

    // MARK: - Debugging

    func rollbackUserResource(for resourceName: String, storageType: StorageType) {
        let key = "migrated_\(resourceName)_\(storageType.rawValue)"
        UserDefaults.standard.removeObject(forKey: key)
        print("🔄 Rollback Migration: \(resourceName)")
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

    private var svgDirectoryName: String { "svgs" }

    /// Stellt sicher, dass das SVG-Verzeichnis existiert (lokal oder iCloud, je nach StorageType)
    func ensureSVGDirectoryExists(for storageType: StorageType) async {
        guard let base = baseDirectory(for: storageType) else {
            print("❌ Basisverzeichnis nicht gefunden für \(storageType)")
            return
        }
        
        let svgDir = base.appendingPathComponent(svgDirectoryName)
        if !FileManager.default.fileExists(atPath: svgDir.path) {
            do {
                try FileManager.default.createDirectory(at: svgDir, withIntermediateDirectories: true)
                print("📂 SVG-Verzeichnis erstellt: \(svgDir.lastPathComponent)")
            } catch {
                print("❌ Fehler beim Erstellen des SVG-Verzeichnisses: \(error)")
            }
        }
    }

    /// Backup des SVG-Verzeichnisses an eine Ziel-URL
    func backupSVGDirectory(storageType: StorageType, to destinationURL: URL) throws {
        guard let base = baseDirectory(for: storageType) else { return }
        let svgDir = base.appendingPathComponent(svgDirectoryName)
        
        if FileManager.default.fileExists(atPath: svgDir.path) {
            let destDir = destinationURL.appendingPathComponent(svgDirectoryName)
            try? FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            
            let files = try FileManager.default.contentsOfDirectory(at: svgDir, includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "svg" {
                let target = destDir.appendingPathComponent(file.lastPathComponent)
                try? FileManager.default.copyItem(at: file, to: target)
            }
        }
    }

    /// Migration des SVG-Verzeichnisses von einem StorageType zu einem anderen
    func migrateSVGDirectory(from sourceStorage: StorageType, to targetStorage: StorageType) throws {
        guard let sourceBase = baseDirectory(for: sourceStorage),
              let targetBase = baseDirectory(for: targetStorage) else { return }

        let sourceSVG = sourceBase.appendingPathComponent(svgDirectoryName)
        let targetSVG = targetBase.appendingPathComponent(svgDirectoryName)

        if !FileManager.default.fileExists(atPath: sourceSVG.path) {
            print("⚠️ Keine SVGs vorhanden zum Migrieren.")
            return
        }

        if !FileManager.default.fileExists(atPath: targetSVG.path) {
            try FileManager.default.createDirectory(at: targetSVG, withIntermediateDirectories: true)
        }

        let files = try FileManager.default.contentsOfDirectory(at: sourceSVG, includingPropertiesForKeys: nil)
        for file in files where file.pathExtension == "svg" {
            let destination = targetSVG.appendingPathComponent(file.lastPathComponent)
            if !FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.copyItem(at: file, to: destination)
                print("📄 SVG migriert: \(file.lastPathComponent)")
            }
        }
    }
}

