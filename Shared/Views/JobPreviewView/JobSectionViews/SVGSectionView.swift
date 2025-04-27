//
//  SvgSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// SVGSectionView.swift
import SwiftUI
import SVGView

struct SVGSectionView: View {
    @Binding var currentJob: PlotJobData
    @Binding var svgFileName: String?
    @Binding var showingFileImporter: Bool
    @Binding var showSourcePreview: Bool

    @EnvironmentObject var store: GenericStore<PlotJobData>

    var body: some View {
        CollapsibleSection(title: "SVG", systemImage: "photo") {
            VStack(alignment: .leading, spacing: 10) {
                Toggle("Code-Ansicht anzeigen", isOn: $showSourcePreview)

                if let name = svgFileName {
                    Text("SVG: \(name)")
                        .font(.subheadline)
                } else {
                    Text("Keine SVG-Datei ausgewählt")
                        .foregroundColor(.secondary)
                }

                if !currentJob.svgFilePath.isEmpty,
                   let url = URL(string: currentJob.svgFilePath),
                   FileManager.default.fileExists(atPath: url.path) {
                    SVGView(contentsOf: url)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .clipped()
                } else {
                    Text("SVG-Datei konnte nicht geladen werden.")
                        .foregroundColor(.red)
                }

                Button("SVG-Datei auswählen") {
                    showingFileImporter = true
                }
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.svg],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let selectedURL = urls.first {
                    if selectedURL.startAccessingSecurityScopedResource() {
                        defer { selectedURL.stopAccessingSecurityScopedResource() }

                        do {
                            let destinationURL = try copyToAppSVGFolder(sourceURL: selectedURL)

                            // ✅ Nur RELATIVEN Pfad speichern
                            let relativePath = "svgs/" + destinationURL.lastPathComponent
                            currentJob.svgFilePath = relativePath
                            svgFileName = destinationURL.lastPathComponent

                            Task {
                                await store.save(item: currentJob, fileName: currentJob.id.uuidString)
                            }

                            print("✅ SVG erfolgreich kopiert nach:", destinationURL.path)
                        } catch {
                            print("❌ Fehler beim Kopieren der SVG:", error.localizedDescription)
                        }
                    } else {
                        print("❌ Konnte Security-Scoped Zugriff auf Datei nicht öffnen!")
                    }
                }
            case .failure(let error):
                print("Fehler beim Importieren: \(error.localizedDescription)")
            }
        }
    }
    
    private func copyToAppSVGFolder(sourceURL: URL) throws -> URL {
        let fileManager = FileManager.default

        // Hole Documents Directory (nicht Application Support!)
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        // Ziel: svgs/ Ordner im Documents
        let svgFolderURL = documentsURL.appendingPathComponent("svgs", isDirectory: true)

        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: svgFolderURL.path, isDirectory: &isDirectory) {
            try fileManager.createDirectory(at: svgFolderURL, withIntermediateDirectories: true)
        } else if !isDirectory.boolValue {
            throw NSError(domain: "App", code: 999, userInfo: [NSLocalizedDescriptionKey: "SVGS-Ordner existiert nicht korrekt."])
        }

        // Ziel-Datei (Pfad + Name)
        let destinationURL = svgFolderURL.appendingPathComponent(sourceURL.lastPathComponent)

        // Wenn schon existiert, löschen
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        // Datei-Inhalt lesen und schreiben
        let fileData = try Data(contentsOf: sourceURL)
        try fileData.write(to: destinationURL)

        return destinationURL
    }
}
