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

    @EnvironmentObject var store: GenericStore<PlotJobData>

    var body: some View {
        CollapsibleSection(title: "SVG", systemImage: "photo") {
            VStack(alignment: .leading, spacing: 10) {

                if let name = svgFileName, !name.isEmpty {
                    Text("SVG: \(name)")
                        .font(.subheadline)
                }

                if let url = resolvedSVGURL() {
                    if FileManager.default.fileExists(atPath: url.path) {
                        // SVGView(contentsOf: url).frame(maxWidth: .infinity, maxHeight: 200).clipped()
                    } else {
                        if let name = svgFileName, !name.isEmpty {
                            Text("SVG-Datei konnte nicht geladen werden.")
                                .foregroundColor(.red)
                        }
                    }
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
            handleFileImport(result: result)
        }
    }

    private func resolvedSVGURL() -> URL? {
        guard !currentJob.svgFilePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        do {
            let documentsURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            return documentsURL.appendingPathComponent(currentJob.svgFilePath)
        } catch {
            appLog("❌ Fehler beim Ermitteln des Documents-Pfads: \(error)")
            return nil
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let selectedURL = urls.first {
                if selectedURL.startAccessingSecurityScopedResource() {
                    defer { selectedURL.stopAccessingSecurityScopedResource() }

                    do {
                        let destinationURL = try copyToAppSVGFolder(sourceURL: selectedURL)
                        let relativePath = "svgs/" + destinationURL.lastPathComponent
                        currentJob.svgFilePath = relativePath
                        svgFileName = destinationURL.lastPathComponent

                        Task {
                            await store.save(item: currentJob, fileName: currentJob.id.uuidString)
                        }

                        appLog("✅ SVG erfolgreich kopiert nach:", destinationURL.path)
                    } catch {
                        appLog("❌ Fehler beim Kopieren der SVG:", error.localizedDescription)
                    }
                } else {
                    appLog("❌ Konnte Security-Scoped Zugriff auf Datei nicht öffnen!")
                }
            }
        case .failure(let error):
            appLog("❌ Fehler beim Importieren: \(error.localizedDescription)")
        }
    }

    private func copyToAppSVGFolder(sourceURL: URL) throws -> URL {
        let fileManager = FileManager.default

        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let svgFolderURL = documentsURL.appendingPathComponent("svgs", isDirectory: true)

        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: svgFolderURL.path, isDirectory: &isDirectory) {
            try fileManager.createDirectory(at: svgFolderURL, withIntermediateDirectories: true)
        } else if !isDirectory.boolValue {
            throw NSError(domain: "App", code: 999, userInfo: [NSLocalizedDescriptionKey: "SVGS-Ordner existiert nicht korrekt."])
        }

        let destinationURL = svgFolderURL.appendingPathComponent(sourceURL.lastPathComponent)

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        let fileData = try Data(contentsOf: sourceURL)
        try fileData.write(to: destinationURL)

        return destinationURL
    }
}
