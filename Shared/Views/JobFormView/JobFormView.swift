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

// TODO: Wenn die SVG Datei zu groß ist: Erzeuge ein passendes jpg, und rendere das als Preview, mit der Möglichkeit das zu zoomen und zu drehen und diese Werte zu übernehmen.
// TODO: Nullpunkt überlagern:  links / rechts oben, mitte, links / rechts unten.
// TODO: Signatur überlagern
// TODO: Verschieben geht, aber zoom nicht, und drehen ist noch nicht implementiert
// TODO: Auf iOS und iPad wird beim öffnen des Jobs die Vorschau nicht geladen. Bei MacOS funktionierts.
// TODO: Wiederverwendbare SplitPanelView oder FormScaffold

// TODO: UUID-Relationen in JSON! https://x.com/i/grok/share/HJ7BTKeYeDGFm4NhUtrOyYWdp

// FIXME: ACHTUNG NICHT UMBENENNEN !! Danach kompliliert iOS nicht mehr.
// MARK: Das ist eine Markierung
// TODO: Das ist ein TODO

// JobFormView.swift (aktualisiert mit Sidebar- und Inspector-Steuerung)
// JobFormView.swift
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct JobFormView: View {
    @AppStorage("jobPreview_sidebarVisible") private var isSidebarVisible: Bool = true
    @AppStorage("jobPreview_inspectorVisible") private var isInspectorVisible: Bool = false

    @Binding var currentJob: JobData
    @Binding var selectedJob: JobData?

    @StateObject private var svgInspectorModel: SVGInspectorModel

    @EnvironmentObject var plotJobStore: GenericStore<JobData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormatData>

    @State private var zoom: Double = 1.0
    @State private var pitch: Double = 0.0
    @State private var origin: CGPoint = .zero
    @State private var svgFileName: String? = nil
    @State private var showingFileImporter = false
    @State private var previewMode: PreviewMode = .svgPreview
    @State private var inspectorWidth: CGFloat = 300
    @State private var showingSettings = false
    @State private var showingInspector = false
    @State private var selectedMachine: MachineData? = nil

    enum PreviewMode: String, CaseIterable, Identifiable {
        case svgPreview = "SVG Preview"
        case codePreview = "Code Preview"
        case plotSimulation = "Plot-Simulation"
        var id: String { rawValue }
    }

    init(currentJob: Binding<JobData>, selectedJob: Binding<JobData?>) {
        self._currentJob = currentJob
        self._selectedJob = selectedJob
        _svgInspectorModel = StateObject(wrappedValue: SVGInspectorModel(job: currentJob.wrappedValue, machine: nil))
    }

    var body: some View {
        Group {
#if os(macOS)
            MacJobPreviewLayoutView(
                svgFileName: $svgFileName,
                showingFileImporter: $showingFileImporter,
                zoom: $zoom,
                pitch: $pitch,
                origin: $origin,
                previewMode: $previewMode,
                isSidebarVisible: $isSidebarVisible,
                isInspectorVisible: $isInspectorVisible,
                inspectorWidth: $inspectorWidth
            )
            .environmentObject(svgInspectorModel)
            .environmentObject(plotJobStore)
            .environmentObject(paperStore)
            .environmentObject(paperFormatsStore)
            .navigationTitle("Job Preview")
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
            .navigationTitle("Job Preview")
#endif
        }
        .onAppear {
            appLog(.info, "Geladener SVG-Pfad:", currentJob.svgFilePath)
            loadActiveJob()
        }
        .onDisappear {
            saveCurrentJob()
        }
    }

    private func loadActiveJob() {
        svgFileName = URL(fileURLWithPath: currentJob.svgFilePath).lastPathComponent
    }

    private func saveCurrentJob() {
        Task {
            let start = Date()
            await svgInspectorModel.save(using: plotJobStore)

            // Aktualisiere den Job in der Liste
            if let index = plotJobStore.items.firstIndex(where: { $0.id == svgInspectorModel.job.id }) {
                plotJobStore.items[index] = svgInspectorModel.job
            }

            // Aktuelles Binding aktualisieren
            currentJob = svgInspectorModel.job

            let duration = Date().timeIntervalSince(start)
            print("Saving job completed in \(duration) seconds")
        }
    }
}
