//
//  SvgPropertyEditorView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 13.04.25.
//

// SvgPropertyEditorView.swift
import SwiftUI

public struct SvgPropertyEditorView: View {
    @Binding var currentJob: PlotJobData
    @EnvironmentObject var store: GenericStore<PlotJobData>  // Verwendung von GenericStore

    // Zugriff auf Papierformat-Vorlagen aus Settings
    @EnvironmentObject var settingsModel: GenericStore<SettingsData>  // Verwendung von GenericStore für SettingsData
    
    @State private var selectedPaper: PaperData
    @State private var isCustomSize: Bool = false
    @State private var customWidth: Double = 210.0
    @State private var customHeight: Double = 297.0

    // interner Initializer
    internal init(currentJob: Binding<PlotJobData>) {
        _currentJob = currentJob
        _selectedPaper = State(initialValue: currentJob.wrappedValue.paper)
        _customWidth = State(initialValue: currentJob.wrappedValue.paper.paperFormat.width)
        _customHeight = State(initialValue: currentJob.wrappedValue.paper.paperFormat.height)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Paper Templates
/*
            Section(header: platformSectionHeader(title: "Papierformat")) {
                Picker("Format", selection: $selectedPaperSize) {
                    ForEach(settingsModel.items) { paperSize in
                        Text(paperSize.name).tag(paperSize)
                    }
                }
                .onChange(of: selectedPaperSize) { updateJob() }

                Toggle("Benutzerdefiniertes Format", isOn: $isCustomSize)
                    .onChange(of: isCustomSize) {
                        if isCustomSize {
                            selectedPaperSize = PaperSize(name: "Custom", width: customWidth, height: customHeight, orientation: 0, note: "")
                        } else {
                            customWidth = selectedPaperSize.width
                            customHeight = selectedPaperSize.height
                        }
                        updateJob()
                    }
            }
*/

            // SVG File Path
            HStack {
                Tools.textField(label: "SVG Dateipfad", value: $currentJob.svgFilePath)
                Text("SVG Dateipfad:")
            }
            .onChange(of: currentJob.svgFilePath) { updateJob() }

            // Current Command Index
            HStack {
                Text("Aktueller Befehl Index:")
                Tools.intTextField(label: "Befehl Index", value: $currentJob.currentCommandIndex)
            }
            .onChange(of: currentJob.currentCommandIndex) { updateJob() }

            // Pitch
            HStack {
                Text("Pitch:")
                Tools.doubleTextField(label: "Pitch", value: $currentJob.pitch)
            }
            .onChange(of: currentJob.pitch) { updateJob() }

            // Zoom
            HStack {
                Text("Zoom:")
                Tools.doubleTextField(label: "Zoom", value: $currentJob.zoom)
            }
            .onChange(of: currentJob.zoom) { updateJob() }

        }
        .padding()
    }
    
    private func updateJob() {
        // Wenn benutzerdefiniertes Format gewählt wurde, speichern wir es
 /* TODO: Wieder einbauen???
        if isCustomSize {
            currentJob.paper.paperFormat.width = PaperSize(name: "Custom", width: customWidth, height: customHeight, orientation: 0, note: "")
        } else {
            currentJob.paperSize = selectedPaperSize
        }
*/
        // Speichern der Änderungen
        Task {
            await store.save(item: currentJob, fileName: currentJob.id.uuidString)
        }
    }
}
