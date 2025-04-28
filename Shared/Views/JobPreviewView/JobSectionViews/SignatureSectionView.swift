//
//  SignatureSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// SignatureSectionView.swift
import SwiftUI

struct SignatureSectionView: View {
    @Binding var currentJob: PlotJobData
    @State private var showingFileImporter = false
    @State private var signatureFileName: String? = nil  // @State für mutablen Zustand

    @EnvironmentObject var store: GenericStore<PlotJobData>

    var body: some View {
        CollapsibleSection(title: "Signatur", systemImage: "signature") {
            VStack(alignment: .leading, spacing: 10) {
                // Anzeige des aktuellen Signatur-Dateinamens
                if let signatureFileName = signatureFileName {
                    HStack {
                        Text("Signatur: \(signatureFileName)")
                            .font(.subheadline)
                        Spacer()
                        Button {
                            deleteCurrentSignature()  // Löschen der Signatur
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Button zum Hinzufügen einer Signatur
                Button("Signatur hinzufügen") {
                    showingFileImporter = true  // Zeige File Importer
                }

                // Eingabefelder für Signatur-Position und Abstände
                VStack(alignment: .leading) {
                    Text("Signatur-Position:")

                    // Sicheres optionales Binding mit Standardwert
                    Picker("Position", selection: Binding(
                        get: { currentJob.signatur?.signatureLocation ?? .bottomRight }, // Fallback-Wert
                        set: { currentJob.signatur?.signatureLocation = $0 }
                    )) {
                        ForEach(SignatureLocation.allCases, id: \.self) { location in
                            Text(location.rawValue).tag(location)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    // Eingabefelder für Abstände
                    VStack(alignment: .leading) {
                        Text("Horizontaler Abstand:")
                        TextField("Abstand", value: Binding(
                            get: { currentJob.signatur?.abstandHorizontal ?? 0.0 }, // Fallback-Wert, wenn nil
                            set: { currentJob.signatur?.abstandHorizontal = $0 }
                        ), formatter: NumberFormatter())
                        .crossPlatformDecimalKeyboard()

                        Text("Vertikaler Abstand:")
                        TextField("Abstand", value: Binding(
                            get: { currentJob.signatur?.abstandVertical ?? 0.0 }, // Fallback-Wert, wenn nil
                            set: { currentJob.signatur?.abstandVertical = $0 }
                        ), formatter: NumberFormatter())
                        .crossPlatformDecimalKeyboard()
                    }
                }
                .padding(.top, 10)
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

    // Funktion zum Laden der SVG-Datei und Speichern der Signatur
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let selectedURL = urls.first {
                if selectedURL.startAccessingSecurityScopedResource() {
                    defer { selectedURL.stopAccessingSecurityScopedResource() }

                    do {
                        let destinationURL = try copyToSignatureFolder(sourceURL: selectedURL)
                        signatureFileName = destinationURL.lastPathComponent
                        
                        // Speichern der Signatur-Daten im aktuellen Job
                        currentJob.signatur = SignatureData(
                            name: destinationURL.lastPathComponent,
                            svgFilePath: destinationURL.relativePath,
                            signatureLocation: .bottomRight, // Standardwert
                            abstandHorizontal: 0.0,
                            abstandVertical: 0.0
                        )

                        Task {
                            await store.save(item: currentJob, fileName: currentJob.id.uuidString)
                        }
                    } catch {
                        appLog(.info, "❌ Fehler beim Speichern der Signatur: \(error.localizedDescription)")
                    }
                }
            }
        case .failure(let error):
            appLog(.info, "❌ Fehler beim Importieren der Signatur: \(error.localizedDescription)")
        }
    }

    // Funktion zum Kopieren der Signatur in den richtigen Ordner
    private func copyToSignatureFolder(sourceURL: URL) throws -> URL {
        let fileManager = FileManager.default
        
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let signatureFolderURL = documentsURL.appendingPathComponent("jobs-data/\(currentJob.id.uuidString)/signature", isDirectory: true)
        
        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: signatureFolderURL.path, isDirectory: &isDirectory) {
            try fileManager.createDirectory(at: signatureFolderURL, withIntermediateDirectories: true)
        } else if !isDirectory.boolValue {
            throw NSError(domain: "App", code: 999, userInfo: [NSLocalizedDescriptionKey: "Signature-Ordner existiert nicht korrekt."])
        }
        
        let destinationURL = signatureFolderURL.appendingPathComponent(sourceURL.lastPathComponent)
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        let fileData = try Data(contentsOf: sourceURL)
        try fileData.write(to: destinationURL)
        
        return destinationURL
    }

    // Funktion zum Löschen der Signatur
    private func deleteCurrentSignature() {
        if let signatureFileName = signatureFileName {
            let fileManager = FileManager.default
            let signatureFolderURL = try? fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("jobs-data/\(currentJob.id.uuidString)/signature/\(signatureFileName)")
            
            if let url = signatureFolderURL, fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
                currentJob.signatur = nil
                // signatureFileName ist jetzt eine @State-Variable, daher ist die Zuweisung hier korrekt
                self.signatureFileName = nil // Wir können 'signatureFileName' direkt auf nil setzen
                
                Task {
                    await store.save(item: currentJob, fileName: currentJob.id.uuidString)
                }
            }
        }
    }
}
