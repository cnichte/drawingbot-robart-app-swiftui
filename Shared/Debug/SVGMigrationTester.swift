//
//  SVGMigrationTester.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// SVGMigrationTester.swift
import Foundation

class SVGMigrationTester {
    
    static func performTest() async {
        appLog(.info, "🚀 Starte SVG-Migrationstest...")

        let service = FileManagerService.shared

        guard let localBase = service.baseDirectory(for: .local),
              let iCloudBase = service.baseDirectory(for: .iCloud) else {
            appLog(.info, "❌ Basisverzeichnisse konnten nicht gefunden werden.")
            return
        }

        let localSVGs = localBase.appendingPathComponent("svgs")
        let iCloudSVGs = iCloudBase.appendingPathComponent("svgs")

        do {
            await service.ensureSVGDirectoryExists(for: .local)

            let testSVG = """
            <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
                <circle cx="50" cy="50" r="40" stroke="black" stroke-width="2" fill="red" />
            </svg>
            """
            let dummyFile = localSVGs.appendingPathComponent("migration-test.svg")

            if !FileManager.default.fileExists(atPath: dummyFile.path) {
                try testSVG.data(using: .utf8)?.write(to: dummyFile)
                appLog(.info, "✅ Dummy-SVG-Datei erstellt: \(dummyFile.lastPathComponent)")
            } else {
                appLog(.info, "ℹ️ Dummy-SVG existiert bereits.")
            }

            try service.migrateSVGDirectory(from: .local, to: .iCloud)

            let files = try FileManager.default.contentsOfDirectory(atPath: iCloudSVGs.path)
            if files.contains("migration-test.svg") {
                appLog(.info, "🎯 Migration erfolgreich: migration-test.svg gefunden in iCloud!")
            } else {
                appLog(.info, "⚠️ Migration fehlgeschlagen: migration-test.svg nicht in iCloud gefunden.")
            }

        } catch {
            appLog(.info, "❌ Fehler während des SVG-Migrationstests: \(error.localizedDescription)")
        }
    }
    
    static func resetTestSVGs() async {
        appLog(.info, "🧹 Lösche Test-SVG-Dateien...")

        let service = FileManagerService.shared

        guard let localBase = service.baseDirectory(for: .local),
              let iCloudBase = service.baseDirectory(for: .iCloud) else {
            appLog(.info, "❌ Basisverzeichnisse konnten nicht gefunden werden.")
            return
        }

        let paths = [
            localBase.appendingPathComponent("svgs/migration-test.svg"),
            iCloudBase.appendingPathComponent("svgs/migration-test.svg")
        ]

        for path in paths {
            if FileManager.default.fileExists(atPath: path.path) {
                do {
                    try FileManager.default.removeItem(at: path)
                    appLog(.info, "🗑️ Test-SVG gelöscht: \(path.lastPathComponent)")
                } catch {
                    appLog(.info, "❌ Fehler beim Löschen von \(path.lastPathComponent): \(error.localizedDescription)")
                }
            } else {
                appLog(.info, "ℹ️ Keine Test-SVG vorhanden unter: \(path.path)")
            }
        }
    }
}
