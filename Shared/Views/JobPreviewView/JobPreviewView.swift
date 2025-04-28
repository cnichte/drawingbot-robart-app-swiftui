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

    var body: some View {
        Group {
            if UIDevice.current.userInterfaceIdiom == .pad {
                // Split View für iPad mit JobSettingsPanel und JobInspectorPanel
                VStack {
                    HStack {
                        if isSidebarVisible {
                            JobSettingsPanel(
                                currentJob: $currentJob,
                                svgFileName: $svgFileName,
                                showingFileImporter: $showingFileImporter,
                                selectedMachine: $selectedMachine
                            )
                            .frame(maxWidth: 300) // Breite des linken Panels
                            .padding(.top, 10)
                        }

                        Spacer()
                    }

                    Divider()

                    if isInspectorVisible {
                        JobInspectorPanel(selectedMachine: $selectedMachine)
                            .frame(height: 300) // Höhe des rechten Panels
                            .padding(.top, 10)
                    }

                    previewContent
                        .background(ColorHelper.backgroundColor)
                        .frame(maxHeight: .infinity)
                }
                .navigationTitle("Job Preview")
                .navigationBarItems(
                    leading: Button("Einstellungen") { showingSettings.toggle() },
                    trailing: Button("Inspector") { showingInspector.toggle() }
                )
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
                }
                .sheet(isPresented: $showingInspector) {
                    JobInspectorPanel(selectedMachine: $selectedMachine)
                }
            } else {
                // Für iPhone verwenden wir die Sheets
                VStack {
                    previewContent
                        .background(ColorHelper.backgroundColor)
                }
                .navigationTitle("Job Preview")
                .navigationBarItems(
                    leading: Button("Einstellungen") { showingSettings.toggle() },
                    trailing: Button("Inspector") { showingInspector.toggle() }
                )
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
                }
                .sheet(isPresented: $showingInspector) {
                    JobInspectorPanel(selectedMachine: $selectedMachine)
                }
            }
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        VStack {
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
            await plotJobStore.save(item: currentJob, fileName: currentJob.id.uuidString)
        }
    }
}
