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

// JobPreviewView.swift
import SwiftUI
import SVGView

struct JobPreviewView: View {
    @Binding var goToStep: Int
    @Binding var currentJob: PlotJobData
    
    @EnvironmentObject var plotJobStore: GenericStore<PlotJobData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormat>
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var zoom: Double = 1.0
    @State private var pitch: Double = 0.0
    @State private var origin: CGPoint = .zero
    @State private var svgFileName: String? = nil
    @State private var showingFileImporter = false
    @State private var selectedTab: Int = 0
    @State private var showSourcePreview: Bool = false
    @State private var previewMode: PreviewMode = .svgPreview
    
    enum PreviewMode: String, CaseIterable, Identifiable {
        case svgPreview = "SVG Preview"
        case svgSource = "SVG Quellcode"
        case codePreview = "Code Preview"
        case plotSimulation = "Plot-Simulation"
        
        var id: String { rawValue }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let isCompactLayout = horizontalSizeClass == .compact || geometry.size.width < 700
            
            Group {
                if isCompactLayout {
                    VStack(spacing: 0) {
                        topMenuBar
                        
                        Picker("Ansicht wählen", selection: $selectedTab) {
                            Text("Einstellungen").tag(0)
                            Text("Vorschau").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        if selectedTab == 0 {
                            SettingsPanel(
                                goToStep: $goToStep,
                                currentJob: $currentJob,
                                svgFileName: $svgFileName,
                                showingFileImporter: $showingFileImporter,
                                showSourcePreview: $showSourcePreview,
                                showBottomBar: false
                            )
                            .environmentObject(plotJobStore) // wichtig!
                            .environmentObject(paperStore)
                            .environmentObject(paperFormatsStore)
                        } else {
                            previewContent
                        }
                        
                        bottomButtonBar
                    }
                } else {
                    NavigationSplitView {
                        VStack(spacing: 0) {
                            topMenuBar
                            
                            SettingsPanel(
                                goToStep: $goToStep,
                                currentJob: $currentJob,
                                svgFileName: $svgFileName,
                                showingFileImporter: $showingFileImporter,
                                showSourcePreview: $showSourcePreview,
                                showBottomBar: false
                            )
                            .environmentObject(plotJobStore) // wichtig!
                            .environmentObject(paperStore)
                            .environmentObject(paperFormatsStore)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity)
                            .environmentObject(paperFormatsStore) // HIER wichtig!
                        }
                    } detail: {
                        previewContent
                    }
                }
            }
            .onAppear {
                loadActiveJob()
            }
        }
    }
    
    var topMenuBar: some View {
        HStack {
            Text("🧭 Job-Menüleiste")
                .font(.headline)
            Spacer()
            Menu {
                Picker("Vorschau-Modus", selection: $previewMode) {
                    ForEach(PreviewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            } label: {
                Label("Ansicht wechseln", systemImage: "slider.horizontal.3")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    @ViewBuilder
    var previewContent: some View {
        Group {
            switch previewMode {
            case .svgPreview:
                PaperPreview(zoom: $zoom, pitch: $pitch, origin: $origin, job: currentJob)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorHelper.backgroundColor)
        .clipped()
    }
    
    var bottomButtonBar: some View {
        HStack {
            Button("◀︎ Zurück") {
                goToStep = 1
            }
            Spacer()
            Button("Weiter ▶︎") {
                goToStep = 3
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func loadActiveJob() {
        svgFileName = URL(fileURLWithPath: currentJob.svgFilePath).lastPathComponent
    }
}
