//
//  JobPreviewView.swift
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

// JobPreviewView.swift (aktualisiert mit Sidebar- und Inspector-Steuerung)
// JobPreviewView.swift
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct JobPreviewView: View {
    @AppStorage("jobPreview_sidebarVisible") private var isSidebarVisible: Bool = true
    @AppStorage("jobPreview_inspectorVisible") private var isInspectorVisible: Bool = false
    
    @Binding var currentJob: PlotJobData
    @Binding var selectedJob: PlotJobData?
    
    @EnvironmentObject var plotJobStore: GenericStore<PlotJobData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormat>
    
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
        case svgSource = "SVG Quellcode"
        case codePreview = "Code Preview"
        case plotSimulation = "Plot-Simulation"
        var id: String { rawValue }
    }
    
    init(currentJob: Binding<PlotJobData>, selectedJob: Binding<PlotJobData?>) {
        self._currentJob = currentJob
        self._selectedJob = selectedJob
    }
    
    var body: some View {
        Group {
#if os(macOS)
            // macOS: Ursprüngliche CustomSplitView für Stabilität
            CustomSplitView(
                isLeftVisible: $isSidebarVisible,
                isRightVisible: $isInspectorVisible,
                rightPanelWidth: $inspectorWidth,
                leftView: {
                    JobSettingsPanel(
                        currentJob: $currentJob,
                        svgFileName: $svgFileName,
                        showingFileImporter: $showingFileImporter,
                        selectedMachine: $selectedMachine
                    )
                    .environmentObject(plotJobStore)
                    .environmentObject(paperStore)
                    .environmentObject(paperFormatsStore)
                },
                centerView: {
                    previewContent
                        .background(ColorHelper.backgroundColor)
                        .toolbar {
                            ToolbarItem(placement: .automatic) {
                                Picker("Vorschau", selection: $previewMode) {
                                    ForEach(PreviewMode.allCases) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                            }
                            ToolbarItem(placement: .automatic) {
                                Button(isSidebarVisible ? "Sidebar ausblenden" : "Sidebar einblenden") {
                                    isSidebarVisible.toggle()
                                }
                            }
                            ToolbarItem(placement: .automatic) {
                                Button(isInspectorVisible ? "Inspector ausblenden" : "Inspector einblenden") {
                                    isInspectorVisible.toggle()
                                }
                            }
                        }
                },
                rightView: {
                    JobInspectorPanel(selectedMachine: $selectedMachine)
                }
            )
            .navigationTitle("Job Preview")
#else
            // iOS: Unterscheide zwischen iPad und iPhone
            if UIDevice.current.userInterfaceIdiom == .pad {
                // iPad: JobSettingsPanel links, previewContent rechts, Inspector als Sheet
                HStack {
                    if isSidebarVisible {
                        JobSettingsPanel(
                            currentJob: $currentJob,
                            svgFileName: $svgFileName,
                            showingFileImporter: $showingFileImporter,
                            selectedMachine: $selectedMachine
                        )
                        .environmentObject(plotJobStore)
                        .environmentObject(paperStore)
                        .environmentObject(paperFormatsStore)
                        .frame(maxWidth: 300)
                        .padding(.vertical, 10)
                    }
                    
                    previewContent
                        .background(ColorHelper.backgroundColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .navigationTitle("Job Preview")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Inspector") { showingInspector.toggle() }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(isSidebarVisible ? "Sidebar ausblenden" : "Sidebar einblenden") {
                            isSidebarVisible.toggle()
                        }
                    }
                }
                .sheet(isPresented: $showingInspector) {
                    JobInspectorPanel(selectedMachine: $selectedMachine)
                        .frame(minWidth: 300, maxWidth: 400)
                        .presentationDetents([.fraction(0.5)])
                        .presentationDragIndicator(.visible)
                }
            } else {
                // iPhone: previewContent mit Sheets für Settings und Inspector
                VStack {
                    previewContent
                        .background(ColorHelper.backgroundColor)
                }
                .navigationTitle("Job Preview")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Einstellungen") { showingSettings.toggle() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Inspector") { showingInspector.toggle() }
                    }
                }
                .sheet(isPresented: $showingSettings) {
                    JobSettingsPanel(
                        currentJob: $currentJob,
                        svgFileName: $svgFileName,
                        showingFileImporter: $showingFileImporter,
                        selectedMachine: $selectedMachine
                    )
                    .environmentObject(plotJobStore)
                    .environmentObject(paperStore)
                    .environmentObject(paperFormatsStore)
                    .presentationDetents([.fraction(0.95)]) // Geändert von 0.5 auf 0.95
                    .presentationDragIndicator(.visible)
                }
                .sheet(isPresented: $showingInspector) {
                    JobInspectorPanel(selectedMachine: $selectedMachine)
                        .presentationDetents([.fraction(0.95)]) // Geändert von 0.5 auf 0.95
                        .presentationDragIndicator(.visible)
                }
            }
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
    
    // State für den ausgewählten Zoom-Wert (in Prozent)
    @State private var selectedZoom: Int = 100
    // Array mit Zoomstufen von 10% bis 200% in 10%-Schritten
    private let zoomLevels = Array(10...200).filter { $0 % 10 == 0 }
    
    @ViewBuilder
    private var previewContent: some View {
        
        VStack {
            
            Menubar(
                title: "Actions",
                systemImage: "",
                toolbar: { // TODO: on macOS and iPad okay - on iPhone to much spacce
                    HStack(spacing: 12) {
                        VStack { 
                           /*
                            // Beispiel: Ein Bild, das mit dem Zoomfaktor skaliert wird
                            Image(systemName: "star.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .scaleEffect(CGFloat(selectedZoom) / 100.0) // Zoomfaktor anwenden
                         */
                            // Picker für die Zoomstufen
                            Picker("Zoomstufe", selection: $selectedZoom) {
                                ForEach(zoomLevels, id: \.self) { level in
                                    Text("\(level)%").tag(level)
                                }
                            }
                            .pickerStyle(.menu) // Stil des Pickers (z. B. Dropdown-Menü)
                            .padding()
                        }
                    }
                }
            )
            
            switch previewMode {
            case .svgPreview:
                PaperPreview(zoom: $zoom, pitch: $pitch, origin: $origin, job: $currentJob)
            case .svgSource:
                PaperSourcePreview(job: currentJob)
            case .codePreview:
                Text("Code Preview kommt hier hin")
                    .foregroundColor(.gray)
            case .plotSimulation:
                Text("Plot-Simulation kommt hier hin")
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
    
    private func loadActiveJob() {
        svgFileName = URL(fileURLWithPath: currentJob.svgFilePath).lastPathComponent
    }
    
    private func saveCurrentJob() {
        Task {
            appLog(.error, "Saving job started")
            let start = Date()
            await plotJobStore.save(item: currentJob, fileName: currentJob.id.uuidString)
            let duration = Date().timeIntervalSince(start)
            appLog(.error, "Saving job completed in \(duration) seconds")
        }
    }
}
