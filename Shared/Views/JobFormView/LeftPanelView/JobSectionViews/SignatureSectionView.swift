//
//  SignatureSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// SignatureSectionView.swift
import SwiftUI

struct SignatureSectionView: View {
    @EnvironmentObject var model: SVGInspectorModel
    @EnvironmentObject var assetStores: AssetStores // Ändere von store zu assetStores für Konsistenz

    @State private var showingFileImporter = false
    @State private var signatureFileName: String? = nil

    var body: some View {
        CollapsibleSection(title: "Signatur", systemImage: "signature") {
            VStack(alignment: .leading, spacing: 10) {
                if let name = model.jobBox.signatur?.name {
                    HStack {
                        Text("Signatur: \(name)")
                            .font(.subheadline)
                        Spacer()
                        Button {
                            deleteCurrentSignature()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button("Signatur hinzufügen") {
                    showingFileImporter = true
                }

                VStack(alignment: .leading) {
                    Text("Signatur-Position:")
                    Picker("Position", selection: Binding(
                        get: { model.jobBox.signatur?.signatureLocation ?? .bottomRight },
                        set: { newValue in
                            appLog(.info, "Binding set signatureLocation to: \(newValue.rawValue)")
                            if model.jobBox.signatur == nil {
                                model.jobBox.signatur = SignatureData(
                                    name: "",
                                    svgFilePath: "",
                                    signatureLocation: newValue,
                                    abstandHorizontal: 0,
                                    abstandVertical: 0
                                )
                            } else {
                                model.jobBox.signatur?.signatureLocation = newValue
                            }
                            model.syncJobBoxBack()
                        }
                    )) {
                        ForEach(SignatureLocation.allCases, id: \.self) { location in
                            Text(location.rawValue).tag(location)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: model.jobBox.signatur?.signatureLocation) { _, newValue in
                        appLog(.info, "Picker signatureLocation changed to: \(newValue?.rawValue ?? "nil")")
                    }

                    VStack(alignment: .leading) {
                        Text("Horizontaler Abstand:")
                        TextField("Abstand", value: Binding(
                            get: { model.jobBox.signatur?.abstandHorizontal ?? 0 },
                            set: { newValue in
                                appLog(.info, "Binding set abstandHorizontal to: \(newValue)")
                                if model.jobBox.signatur == nil {
                                    model.jobBox.signatur = SignatureData(
                                        name: "",
                                        svgFilePath: "",
                                        signatureLocation: .bottomRight,
                                        abstandHorizontal: newValue,
                                        abstandVertical: 0
                                    )
                                } else {
                                    model.jobBox.signatur?.abstandHorizontal = newValue
                                }
                                model.syncJobBoxBack()
                            }
                        ), formatter: NumberFormatter())
                        .crossPlatformDecimalKeyboard()

                        Text("Vertikaler Abstand:")
                        TextField("Abstand", value: Binding(
                            get: { model.jobBox.signatur?.abstandVertical ?? 0 },
                            set: { newValue in
                                appLog(.info, "Binding set abstandVertical to: \(newValue)")
                                if model.jobBox.signatur == nil {
                                    model.jobBox.signatur = SignatureData(
                                        name: "",
                                        svgFilePath: "",
                                        signatureLocation: .bottomRight,
                                        abstandHorizontal: 0,
                                        abstandVertical: newValue
                                    )
                                } else {
                                    model.jobBox.signatur?.abstandVertical = newValue
                                }
                                model.syncJobBoxBack()
                            }
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
        .onAppear {
            appLog(.info, "SignatureSectionView appeared, current signatur: \(model.jobBox.signatur?.name ?? "nil"), location: \(model.jobBox.signatur?.signatureLocation.rawValue ?? "nil")")
        }
    }

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let selectedURL = urls.first, selectedURL.startAccessingSecurityScopedResource() {
                defer { selectedURL.stopAccessingSecurityScopedResource() }

                do {
                    let destinationURL = try copyToSignatureFolder(sourceURL: selectedURL)
                    signatureFileName = destinationURL.lastPathComponent

                    model.jobBox.signatur = SignatureData(
                        name: destinationURL.lastPathComponent,
                        svgFilePath: destinationURL.relativePath,
                        signatureLocation: .bottomRight,
                        abstandHorizontal: 0.0,
                        abstandVertical: 0.0
                    )
                    model.syncJobBoxBack()

                    Task {
                        await model.save(using: assetStores.plotJobStore)
                        appLog(.info, "Saved signature: \(destinationURL.lastPathComponent)")
                    }
                } catch {
                    appLog(.error, "❌ Fehler beim Speichern der Signatur: \(error.localizedDescription)")
                }
            }
        case .failure(let error):
            appLog(.error, "❌ Fehler beim Importieren der Signatur: \(error.localizedDescription)")
        }
    }

    private func copyToSignatureFolder(sourceURL: URL) throws -> URL {
        let fileManager = FileManager.default
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let signatureFolderURL = documentsURL.appendingPathComponent("jobs-data/\(model.job.id.uuidString)/signature", isDirectory: true)

        if !fileManager.fileExists(atPath: signatureFolderURL.path) {
            try fileManager.createDirectory(at: signatureFolderURL, withIntermediateDirectories: true)
        }

        let destinationURL = signatureFolderURL.appendingPathComponent(sourceURL.lastPathComponent)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }

        let fileData = try Data(contentsOf: sourceURL)
        try fileData.write(to: destinationURL)
        return destinationURL
    }

    private func deleteCurrentSignature() {
        if let fileName = model.jobBox.signatur?.name {
            let fileManager = FileManager.default
            let signatureURL = try? fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("jobs-data/\(model.job.id.uuidString)/signature/\(fileName)")

            if let url = signatureURL, fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
                model.jobBox.signatur = nil
                model.syncJobBoxBack()
                signatureFileName = nil

                Task {
                    await model.save(using: assetStores.plotJobStore)
                    appLog(.info, "Deleted signature: \(fileName)")
                }
            }
        }
    }
}
