//
//  JobFormView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.
//
// https://stackoverflow.com/questions/73100626/uploading-svg-images-to-swiftui/73401775#73401775
// https://github.com/SDWebImage/SDWebImageSVGCoder
// https://github.com/SDWebImage/SDWebImageSwiftUI

// Toolbar
// https://www.youtube.com/watch?v=jTW5Z-kyL8g
//
// /Users/cnichte/Library/Containers/de.nichte.Drawingbot-RobArt/Data/Documents
// ~/Library/Containers/de.cnichte.Drawingbot-RobArt/Data/Documents/svgs

// Property editor for editing job properties
// PropertyEditorView(currentJob: $currentJob)

// TODO: Nullpunkt überlagern:  links / rechts oben, mitte, links / rechts unten.
// TODO: Signatur überlagern
// TODO: UUID-Relationen in JSON! https://x.com/i/grok/share/HJ7BTKeYeDGFm4NhUtrOyYWdp

// MARK: Das ist eine Markierung
// TODO: Das ist ein TODO

// JobFormView.swift (aktualisiert mit Sidebar- und Inspector-Steuerung)
// JobFormView.swift
import SwiftUI
#if os(iOS)
import UIKit
#endif

// --- neu: für Snapshot Funktionalität
import UniformTypeIdentifiers

// MARK: JobFormView
struct JobFormView: View {
    @AppStorage("jobPreview_sidebarVisible") private var isSidebarVisible: Bool = true
    @AppStorage("jobPreview_inspectorVisible") private var isInspectorVisible: Bool = false

    @Binding var currentJob: JobData
    @Binding var selectedJob: JobData? // TODO: Brauch ich das noch?

    @ObservedObject var svgInspectorModel: SVGInspectorModel

    @EnvironmentObject var plotJobStore: GenericStore<JobData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormatData>

    @State private var zoom: Double = 1.0
    @State private var pitch: Double = 0.0
    @State private var origin: CGPoint = .zero
    
    @State private var svgFileName: String? = nil
    @State private var selectedMachine: MachineData? = nil

    @State private var showingFileImporter = false
    @State private var previewMode: PreviewMode = .svgPreview
    @State private var inspectorWidth: CGFloat = 300
    @State private var showingSettings = false
    @State private var showingInspector = false
    

    enum PreviewMode: String, CaseIterable, Identifiable {
        case svgPreview = "SVG Preview"
        case codePreview = "Code Preview"
        case plotSimulation = "Plot-Simulation"
        var id: String { rawValue }
    }

    init(currentJob: Binding<JobData>, selectedJob: Binding<JobData?>, svgInspectorModel: SVGInspectorModel) {
        self._currentJob = currentJob
        self._selectedJob = selectedJob
        self.svgInspectorModel = svgInspectorModel
    }

    var body: some View {
        Group {
#if os(macOS)
            MacJobPreviewLayoutView(
                svgFileName: $svgFileName,
                showingFileImporter: $showingFileImporter,
                previewMode: $previewMode,
                isSidebarVisible: $isSidebarVisible,
                isInspectorVisible: $isInspectorVisible,
                inspectorWidth: $inspectorWidth
            )
            .environmentObject(svgInspectorModel)
            .environmentObject(plotJobStore)
            .environmentObject(paperStore)
            .environmentObject(paperFormatsStore)
            .navigationTitle("Job")
#else
            Group {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    iPadJobPreviewLayout(
                        currentJob: $currentJob,
                        svgFileName: $svgFileName,
                        showingFileImporter: $showingFileImporter,
                        selectedMachine: $selectedMachine,
                        zoom: $zoom,
                        pitch: $pitch,
                        origin: $origin,
                        previewMode: $previewMode,
                        isSidebarVisible: $isSidebarVisible,
                        showingInspector: $showingInspector
                    )
                } else {
                    iPhoneJobPreviewLayout(
                        currentJob: $currentJob,
                        svgFileName: $svgFileName,
                        showingFileImporter: $showingFileImporter,
                        selectedMachine: $selectedMachine,
                        zoom: $zoom,
                        pitch: $pitch,
                        origin: $origin,
                        previewMode: $previewMode,
                        showingSettings: $showingSettings,
                        showingInspector: $showingInspector
                    )
                }
            }
            .environmentObject(svgInspectorModel)
            .environmentObject(plotJobStore)
            .environmentObject(paperStore)
            .environmentObject(paperFormatsStore)
            .navigationTitle("Job")
#endif
        }
        .onAppear {
            // appLog(.info, "JobFormView.onAppear: geladener SVG-Pfad:", currentJob.svgFilePath)
            //💡 hole aktuelle Jobdaten aus dem Store (falls aktueller Binding-Wert veraltet ist)
            if let latest = plotJobStore.items.first(where: { $0.id == currentJob.id }) {
                currentJob = latest
            }

            loadActiveJob()
        }
        .onDisappear {
            saveCurrentJob()
        }
        .onChange(of: currentJob) { _, newValue in
            svgInspectorModel.job = newValue
        }
    }
    
    // MARK: load save Functions
    
    private func loadActiveJob() {
        appLog(.info, "JobFormView.loadActiveJob: geladener SVG-Pfad:", currentJob.svgFilePath)
        svgFileName = URL(fileURLWithPath: currentJob.svgFilePath).lastPathComponent
    }

    private func saveCurrentJob() {
        
        Task {
            let start = Date()
            await svgInspectorModel.save(using: plotJobStore)
            let duration = Date().timeIntervalSince(start)
            print("✅ Saving job completed in \(duration) seconds")
            
            // --- Neuer Code: Screenshot vom gesamten PaperPanel
            // TODO: Der Inhalt fehlt noch!
            // 1) Errechne Papiermaße in Points
            let fmt = svgInspectorModel.job.paperData.paperFormat
            let isLandscape = svgInspectorModel.job.paperOrientation == .landscape
            let w = CGFloat(isLandscape ? fmt.height : fmt.width)
            let h = CGFloat(isLandscape ? fmt.width  : fmt.height)
            let size = CGSize(width: w, height: h)

            // 2) Erstelle die View-Instanz mit EnvironmentObject
            let panel = PaperPanel()
                .environmentObject(svgInspectorModel)

            // 3) Generiere Snapshot
            if let img = SVGSnapshot.snapshot(of: panel, size: size) {
                // 4) Speicher-Pfad für das Panel-Bild
                let previewFolder = JobsDataFileManager.shared.previewFolder(for: svgInspectorModel.job.id)
                let url = previewFolder.appendingPathComponent("thumbnail.png")
                try? SVGSnapshot.saveThumbnail(img, to: url)
                print("📸 Panel screenshot saved to \(url.path)")
            }
        }
    }
}
