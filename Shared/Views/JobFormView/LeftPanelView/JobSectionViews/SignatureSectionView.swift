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
    @EnvironmentObject var store: GenericStore<JobData>

    @State private var showingFileImporter = false
    @State private var signatureFileName: String? = nil

    var body: some View {
        CollapsibleSection(title: "Signatur", systemImage: "signature") {
            VStack(alignment: .leading, spacing: 10) {
                if let name = model.job.signatur?.name {
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
                    Picker("Position", selection: model.bindingSignature(
                        \SignatureData.signatureLocation,
                        defaultValue: { SignatureData(name: "", svgFilePath: "", signatureLocation: .bottomRight, abstandHorizontal: 0, abstandVertical: 0) }
                    )) {
                        ForEach(SignatureLocation.allCases, id: \.self) { location in
                            Text(location.rawValue).tag(location)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    VStack(alignment: .leading) {
                        Text("Horizontaler Abstand:")
                        TextField("Abstand", value: model.bindingSignature(
                            \SignatureData.abstandHorizontal,
                            defaultValue: { SignatureData(name: "", svgFilePath: "", signatureLocation: .bottomRight, abstandHorizontal: 0, abstandVertical: 0) }
                        ), formatter: NumberFormatter())
                        .crossPlatformDecimalKeyboard()

                        Text("Vertikaler Abstand:")
                        TextField("Abstand", value: model.bindingSignature(
                            \SignatureData.abstandVertical,
                            defaultValue: { SignatureData(name: "", svgFilePath: "", signatureLocation: .bottomRight, abstandHorizontal: 0, abstandVertical: 0) }
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

    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let selectedURL = urls.first, selectedURL.startAccessingSecurityScopedResource() {
                defer { selectedURL.stopAccessingSecurityScopedResource() }

                do {
                    let destinationURL = try copyToSignatureFolder(sourceURL: selectedURL)
                    signatureFileName = destinationURL.lastPathComponent

                    model.job.signatur = SignatureData(
                        name: destinationURL.lastPathComponent,
                        svgFilePath: destinationURL.relativePath,
                        signatureLocation: .bottomRight,
                        abstandHorizontal: 0.0,
                        abstandVertical: 0.0
                    )

                    Task {
                        await store.save(item: model.job, fileName: model.job.id.uuidString)
                    }
                } catch {
                    appLog(.info, "❌ Fehler beim Speichern der Signatur: \(error.localizedDescription)")
                }
            }
        case .failure(let error):
            appLog(.info, "❌ Fehler beim Importieren der Signatur: \(error.localizedDescription)")
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
        if let fileName = model.job.signatur?.name {
            let fileManager = FileManager.default
            let signatureURL = try? fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("jobs-data/\(model.job.id.uuidString)/signature/\(fileName)")

            if let url = signatureURL, fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
                model.job.signatur = nil
                signatureFileName = nil

                Task {
                    await store.save(item: model.job, fileName: model.job.id.uuidString)
                }
            }
        }
    }
}
