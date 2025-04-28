//
//  SVGFileManager.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// JobsDataFileManager.swift
import Foundation
import SwiftUI

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

            if !fileManager.fileExists(atPath: jobsDataDirectory.path) {
                try fileManager.createDirectory(at: jobsDataDirectory, withIntermediateDirectories: true)
                appLog(.info, "jobs-data Ordner erstellt")
            }
        } catch {
            fatalError("Konnte jobs-data-Verzeichnis nicht einrichten: \(error)")
        }
    }

    // MARK: - Verzeichnis Pfade

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

    // MARK: - Verwaltung

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
                appLog(.info, "Ordner erstellt: \(folder.lastPathComponent)")
            }
        }
    }

    func copySVG(toJobID jobID: UUID, from sourceURL: URL) throws -> URL {
        try createFoldersForJob(jobID: jobID)

        let svgFolder = svgFolder(for: jobID)
        let destinationURL = svgFolder.appendingPathComponent(sourceURL.lastPathComponent)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        let data = try Data(contentsOf: sourceURL)
        try data.write(to: destinationURL)

        appLog(.info, "✅ SVG kopiert: \(destinationURL.lastPathComponent)")

        // 👉 Thumbnail erzeugen
        Task {
            await generateThumbnail(for: jobID, svgURL: destinationURL)
        }

        return destinationURL
    }
    
    private func generateThumbnail(for jobID: UUID, svgURL: URL) async {
        let thumbnailURL = previewFolder(for: jobID).appendingPathComponent("thumbnail.png")

        if let image = await SVGSnapshot.generateThumbnail(from: svgURL, maxSize: CGSize(width: 200, height: 200)) {
            do {
                try SVGSnapshot.saveThumbnail(image, to: thumbnailURL)
                appLog(.info, "🖼️ Thumbnail gespeichert: \(thumbnailURL.lastPathComponent)")
            } catch {
                appLog(.info, "❌ Fehler beim Speichern des Thumbnails: \(error)")
            }
        }
    }

    func deleteAllJobData(for jobID: UUID) {
        let jobFolder = jobFolder(for: jobID)

        if fileManager.fileExists(atPath: jobFolder.path) {
            do {
                try fileManager.removeItem(at: jobFolder)
                appLog(.info, "Job-Verzeichnis gelöscht: \(jobFolder.lastPathComponent)")
            } catch {
                appLog(.info, "Fehler beim Löschen des Job-Verzeichnisses: \(error.localizedDescription)")
            }
        }
    }

    func saveThumbnail(_ image: PlatformImage, for jobID: UUID) throws {
        try createFoldersForJob(jobID: jobID)
        let previewURL = previewFolder(for: jobID).appendingPathComponent("thumbnail.png")

        if let data = image.pngData() {
            try data.write(to: previewURL)
            appLog(.info, "🖼️ Thumbnail gespeichert für \(jobID)")
        } else {
            throw NSError(domain: "JobsDataFileManager", code: 500, userInfo: [NSLocalizedDescriptionKey: "Konnte Thumbnail nicht als PNG speichern."])
        }
    }
}
