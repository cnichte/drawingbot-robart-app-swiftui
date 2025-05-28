//
//  SvgSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// SVGSectionView.swift
import SwiftUI

struct SVGSectionView: View {
    @EnvironmentObject var model: SVGInspectorModel
    
    @Binding var svgFileName: String?
    @Binding var showingFileImporter: Bool

    @EnvironmentObject var store: GenericStore<JobData>

    var body: some View {
        CollapsibleSection(title: "SVG", systemImage: "photo", toolbar: { EmptyView() }) {
            VStack(alignment: .leading, spacing: 10) {

                if let name = svgFileName, !name.isEmpty {
                    HStack {
                        Text("SVG: \(name)")
                            .font(.subheadline)
                        Spacer()
                        Button {
                            deleteCurrentSVG()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let url = resolvedSVGURL() {
                    if FileManager.default.fileExists(atPath: url.path) {
                        // mach nix
                    } else {
                        if let name = svgFileName, !name.isEmpty {
                            // Der Fehler tritt hier auf, obwohl hier gar nix gemacht wird.
                            // Das müssetn wir mal genauer debuggen
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
        
        // Sobald svgFileName gesetzt ist, baue daraus den vollständigen Pfad
        guard
            let name = svgFileName,
            !name.isEmpty
        else { return nil }
        
        // Basis: ~/Documents
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!

        // ~/Documents/jobs-data/<JobID>/svg
        let svgFolder = docs
            .appendingPathComponent("jobs-data")
            .appendingPathComponent(model.job.id.uuidString)
            .appendingPathComponent("svg")
        
        // ~/Documents/jobs-data/<JobID>/svg/<Dateiname>
        let fullURL = svgFolder.appendingPathComponent(name)

        // appLog(.info, "🔍 Resolved SVG → \(fullURL.path), exists: \(FileManager.default.fileExists(atPath: fullURL.path))")
        return fullURL
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let selectedURL = urls.first {
                if selectedURL.startAccessingSecurityScopedResource() {
                    defer { selectedURL.stopAccessingSecurityScopedResource() }

                    do {
                        let destinationURL = try JobsDataFileManager.shared.copySVG(toJobID: model.job.id, from: selectedURL)
                        
                        // arbeitskopie
                        let workingCopyURL = JobsDataFileManager.shared.svgFolder(for: model.job.id).appendingPathComponent("working.svg")
                        try Data(contentsOf: destinationURL).write(to: workingCopyURL)
                        
                        // original
                        let relativePath = "jobs-data/\(model.job.id.uuidString)/svg/\(destinationURL.lastPathComponent)"
                        
                        // 1) Update in JobBox
                        model.jobBox.svgFilePath = relativePath
                        // 2) UI-State aktualisieren
                        svgFileName = destinationURL.lastPathComponent
 /*
                        Task {
                            await model.save(using: store)
                            DispatchQueue.main.async {
                                if let idx = store.items.firstIndex(where: { $0.id == model.job.id }) {
                                    store.items[idx] = model.job
                                }
                            }
                        }
*/
/*
                        Task {
                            await store.save(item: model.job, fileName: model.job.id.uuidString)
                            // 2) aktualisiere store.items direkt,
                            //    damit beim nächsten "onReceive" wirklich dein neuer Pfad drinsteht
                            DispatchQueue.main.async {
                                if let idx = store.items.firstIndex(where: { $0.id == model.job.id }) {
                                    store.items[idx] = model.job
                                }
                            }
                        }
*/
                    } catch {
                        appLog(.info, "❌ Fehler beim Kopieren der SVG:", error.localizedDescription)
                    }
                } else {
                    appLog(.info, "❌ Konnte Security-Scoped Zugriff auf Datei nicht öffnen!")
                }
            }
        case .failure(let error):
            appLog(.info, "❌ Fehler beim Importieren: \(error.localizedDescription)")
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
    
    private func deleteCurrentSVG() {
        JobsDataFileManager.shared.deleteAllJobData(for: model.job.id)
        model.job.svgFilePath = ""
        svgFileName = nil

        Task {
            await store.save(item: model.job, fileName: model.job.id.uuidString)
        }
    }
}
