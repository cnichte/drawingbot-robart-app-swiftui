//
//  SettingsMigrator.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 10.04.25.
//

import Foundation

class SettingsMigrator {
    private let fileManager = FileManager.default
    private let service = FileManagerService()

    func migrate(from source: StorageType,
                 to target: StorageType,
                 deleteOriginal: Bool = false) throws {
        
        let sourceDir = try requireDirectory(for: source)
        let targetDir = try requireDirectory(for: target)

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

    private func requireDirectory(for storage: StorageType) throws -> URL {
        guard let url = service.getDirectoryURL(for: storage) else {
            throw NSError(domain: "Directory not found", code: 42)
        }

        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }

        return url
    }
}

