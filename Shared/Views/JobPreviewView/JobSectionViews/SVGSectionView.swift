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

                if !currentJob.svgFilePath.isEmpty, let url = URL(string: currentJob.svgFilePath) {
                    SVGView(contentsOf: url)
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .clipped()
                } else {
                    Text("SVG-Datei konnte nicht geladen werden.")
                        .foregroundColor(.red)
                }

                Button("SVG-Datei auswählen") {
                    showingFileImporter.toggle()
                }
            }
        }
    }
}
