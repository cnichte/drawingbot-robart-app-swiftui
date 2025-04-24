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
    func getDirectoryURL(for type: StorageType) -> URL? {
        switch type {
        case .local:
            let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            return url?.appendingPathComponent(settingsSubdirectory)

        case .iCloud:
            guard let cloudURL = fileManager.url(forUbiquityContainerIdentifier: nil) else {
                print("⚠️ iCloud NICHT verfügbar oder nicht aktiviert.")
                return nil
            }
            let finalURL = cloudURL.appendingPathComponent("Documents").appendingPathComponent(settingsSubdirectory)
            print("✅ iCloud verfügbar: \(finalURL.path)")
            return finalURL
        }
    }

    // MARK: - One-time Migration
    static func migrateOnce<T: Codable & Identifiable>(
        resourceName: String,
        to directoryName: String,
        as type: T.Type
    ) throws {
        let migrationKey = "migrated_\(resourceName)"
        if UserDefaults.standard.bool(forKey: migrationKey) {
            return
        }

        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            throw NSError(domain: "Resource \(resourceName).json nicht gefunden", code: 1)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let items = try decoder.decode([T].self, from: data)

        let fileManager = FileManager.default
        let service = FileManagerService()

        guard let targetDir = service.getDirectoryURL(for: .local)?.deletingLastPathComponent().appendingPathComponent(directoryName) else {
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
