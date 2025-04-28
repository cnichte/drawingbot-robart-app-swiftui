//
//  SVGFileManager.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// JobsDataFileManager.swift
import Foundation

class JobsDataFileManager {
    static let shared = JobsDataFileManager()

    private let fileManager = FileManager.default
    private let jobsDataDirectory: URL

    private init() {
        do {
            let documentsURL = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.jobsDataDirectory = documentsURL.appendingPathComponent("jobs-data", isDirectory: true)

            // jobs-data Verzeichnis sicherstellen
            if !fileManager.fileExists(atPath: jobsDataDirectory.path) {
                try fileManager.createDirectory(at: jobsDataDirectory, withIntermediateDirectories: true)
                appLog("📂 jobs-data Ordner erstellt")
            }
        } catch {
            fatalError("❌ Konnte jobs-data-Verzeichnis nicht einrichten: \(error)")
        }
    }

    // MARK: - Public Funktionen

    func jobFolder(for jobID: UUID) -> URL {
        jobsDataDirectory.appendingPathComponent(jobID.uuidString, isDirectory: true)
    }

    func svgFolder(for jobID: UUID) -> URL {
        jobFolder(for: jobID).appendingPathComponent("svg", isDirectory: true)
    }

    func gcodeFolder(for jobID: UUID) -> URL {
        jobFolder(for: jobID).appendingPathComponent("gcode", isDirectory: true)
    }

    func previewFolder(for jobID: UUID) -> URL {
        jobFolder(for: jobID).appendingPathComponent("preview", isDirectory: true)
    }

    func metadataFolder(for jobID: UUID) -> URL {
        jobFolder(for: jobID).appendingPathComponent("metadata", isDirectory: true)
    }

    /// Erzeugt einen neuen Ordnerbaum für einen Job
    func createFoldersForJob(jobID: UUID) throws {
        let folders = [
            svgFolder(for: jobID),
            gcodeFolder(for: jobID),
            previewFolder(for: jobID),
            metadataFolder(for: jobID)
        ]

        for folder in folders {
            if !fileManager.fileExists(atPath: folder.path) {
                try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
                appLog("📁 Ordner erstellt: \(folder.lastPathComponent)")
            }
        }
    }

    /// Kopiert eine Datei in den SVG-Ordner des Jobs
    func copySVG(toJobID jobID: UUID, from sourceURL: URL) throws -> URL {
        try createFoldersForJob(jobID: jobID)

        let svgFolder = svgFolder(for: jobID)
        let destinationURL = svgFolder.appendingPathComponent(sourceURL.lastPathComponent)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        let data = try Data(contentsOf: sourceURL)
        try data.write(to: destinationURL)

        appLog("✅ SVG kopiert: \(destinationURL.lastPathComponent)")
        return destinationURL
    }

    /// Löscht ein komplettes Job-Verzeichnis
    func deleteAllJobData(for jobID: UUID) {
        let jobFolder = jobFolder(for: jobID)

        if fileManager.fileExists(atPath: jobFolder.path) {
            do {
                try fileManager.removeItem(at: jobFolder)
                appLog("🗑️ Job-Verzeichnis gelöscht: \(jobFolder.lastPathComponent)")
            } catch {
                appLog("❌ Fehler beim Löschen des Job-Verzeichnisses: \(error.localizedDescription)")
            }
        }
    }
}
