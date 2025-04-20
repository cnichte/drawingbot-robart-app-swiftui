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

//  FileManagerService.swift
import Foundation

// Definiere StorageType direkt in FileManagerService.swift
enum StorageType: String {
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
}
