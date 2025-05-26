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
        guard !model.job.svgFilePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        let docs = try! FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false)
            let full = docs.appendingPathComponent(model.job.svgFilePath)
            // appLog(.info, "🔍 resolvedSVGURL → \(full.path), exists: \(FileManager.default.fileExists(atPath: full.path))")
            return full
/*
        do {
            let documentsURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            return documentsURL.appendingPathComponent(model.job.svgFilePath)
        } catch {
            appLog(.info, "❌ Fehler beim Ermitteln des Documents-Pfads: \(error)")
            return nil
        }
*/
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
                        // model.job.svgFilePath = relativePath
                        
                        // 1a) Update im reinen JobData
                        model.job.svgFilePath = relativePath
                        // 1b) Update auch im JobBox
                        model.jobBox.svgFilePath = relativePath
                        
                        svgFileName = destinationURL.lastPathComponent
                        
                        // 1c) Jetzt beide zusammen in sync zurückschreiben
                        model.syncJobBoxBack()

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
