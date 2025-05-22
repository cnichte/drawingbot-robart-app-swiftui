//
//  JobInspector_SVGFileInfoView.swift
//  Robart
//
//  Created by Carsten Nichte on 01.05.25.
//

// JobInspector_SVGFileInfoView.swift
import SwiftUI

struct JobInspector_SVGFileInfoView: View {
    @Binding var currentJob: JobData

    @State private var fileSize: String = "–"
    @State private var modifiedDate: String = "–"
    @State private var fileName: String = "–"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allgemeine Datei-Informationen")
                .font(.headline)

            Text("Dateiname: \(fileName)")
            Text("Dateigröße: \(fileSize)")
            Text("Geändert am: \(modifiedDate)")
        }
        .onAppear {
            loadFileInfo()
        }
    }

    private func loadFileInfo() {
        let url = JobsDataFileManager.shared.workingSVGURL(for: currentJob.id)
        fileName = url.lastPathComponent

        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)

            if let size = attrs[.size] as? NSNumber {
                let formatter = ByteCountFormatter()
                formatter.allowedUnits = [.useKB, .useMB]
                formatter.countStyle = .file
                fileSize = formatter.string(fromByteCount: size.int64Value)
            }

            if let modDate = attrs[.modificationDate] as? Date {
                let df = DateFormatter()
                df.dateStyle = .medium
                df.timeStyle = .short
                modifiedDate = df.string(from: modDate)
            }
        } catch {
            fileSize = "Fehler"
            modifiedDate = "Fehler"
        }
    }
}
