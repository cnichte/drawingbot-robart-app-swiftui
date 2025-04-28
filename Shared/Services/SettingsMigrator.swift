//
//  SettingsMigrator.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 10.04.25.
//

// SettingsMigrator.swift
import Foundation

class SettingsMigrator {
    private let fileManager = FileManager.default
    private let service = FileManagerService.shared

    func migrate(from source: StorageType,
                 to target: StorageType,
                 subdirectory: String,
                 deleteOriginal: Bool = false) throws {
        
        guard let sourceBase = service.baseDirectory(for: source),
              let targetBase = service.baseDirectory(for: target) else {
            throw NSError(domain: "Directory not found", code: 42)
        }
        
        let sourceDir = sourceBase.appendingPathComponent(subdirectory)
        let targetDir = targetBase.appendingPathComponent(subdirectory)

        if !fileManager.fileExists(atPath: sourceDir.path) {
            appLog("⚠️ Quelle \(sourceDir.lastPathComponent) existiert nicht. Migration übersprungen.")
            return
        }

        if !fileManager.fileExists(atPath: targetDir.path) {
            try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
        }

        let files = try fileManager.contentsOfDirectory(atPath: sourceDir.path)
        let jsonFiles = files.filter { $0.hasSuffix(".json") }

        for file in jsonFiles {
            let sourceURL = sourceDir.appendingPathComponent(file)
            let targetURL = targetDir.appendingPathComponent(file)

            let data = try Data(contentsOf: sourceURL)
            try data.write(to: targetURL, options: .atomic)

            if deleteOriginal {
                try fileManager.removeItem(at: sourceURL)
            }
        }
    }
}
