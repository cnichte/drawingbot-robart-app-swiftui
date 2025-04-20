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

    @EnvironmentObject var store: GenericStore<PlotJobData>
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
                                store: store,
                                showBottomBar: false
                            )
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
                                store: store,
                                showBottomBar: true
                            )
                            .padding(.horizontal, 12)
                            .frame(maxWidth: .infinity)
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


struct SettingsPanel: View {
    @Binding var goToStep: Int
    @Binding var currentJob: PlotJobData
    @Binding var svgFileName: String?
    @Binding var showingFileImporter: Bool
    @Binding var showSourcePreview: Bool

    var store: GenericStore<PlotJobData>
    var showBottomBar: Bool = false

    private func handleFileSelection(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("No permission to access the resource")
            return
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        let fileManager = FileManager.default
        let destinationURL = getSVGDirectory().appendingPathComponent(url.lastPathComponent)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            
            currentJob.svgFilePath = destinationURL.path
            svgFileName = destinationURL.lastPathComponent
            
            Task {
                await store.save(item: currentJob, fileName: currentJob.id.uuidString)
            }
            
            try fileManager.copyItem(at: url, to: destinationURL)
            
        } catch {
            print("Fehler beim Kopieren der Datei: \(error.localizedDescription)")
        }
    }
    
    private func getSVGDirectory() -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let svgDirectory = directory.appendingPathComponent("svgs")
        
        if !fileManager.fileExists(atPath: svgDirectory.path) {
            do {
                try fileManager.createDirectory(at: svgDirectory, withIntermediateDirectories: true)
            } catch {
                print("Fehler beim Erstellen des Verzeichnisses: \(error.localizedDescription)")
            }
        }
        
        return svgDirectory
    }
    
    private func updateJob() {
        // Speichern der Änderungen
        Task {
            await store.save(item: currentJob, fileName: currentJob.id.uuidString)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                CollapsibleSection(title: "Job", systemImage: "doc.plaintext") {
                    VStack(alignment: .leading) {
                        TextField("Name", text: $currentJob.name)
                        TextEditor(text: $currentJob.description)
                            .frame(minHeight: 80)
                            .padding(4)
                            .background(ColorHelper.backgroundColor)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.gray.opacity(0.3))
                            )
                    }
                    .textFieldStyle(.roundedBorder)
                }

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
                        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.svg]) { result in
                            switch result {
                            case .success(let url):
                                handleFileSelection(url)
                            case .failure(let error):
                                print("Fehler beim Auswählen der Datei: \(error.localizedDescription)")
                            }
                        }
                    }
                    
                    // Property editor for editing job properties
                    SvgPropertyEditorView(currentJob: $currentJob)
                }

                CollapsibleSection(title: "Signatur", systemImage: "signature") {
                    Text("Signatur-Einstellungen folgen...")
                        .foregroundColor(.secondary)
                }

                CollapsibleSection(title: "Papier", systemImage: "doc.plaintext") {
                    VStack(alignment: .leading, spacing: 10) {
                        // Paper Size
                        HStack {
                            Text("Papiergröße-Name")
                            Tools.textField(label: "Papiergröße-Name", value: $currentJob.paperSize.name)
                        }
                        .onChange(of: currentJob.paperSize.name) { updateJob() }
                        
                        // Paper Size Width
                        HStack {
                            Text("Papiergröße-Breite:")
                            Tools.doubleTextField(label: "Papiergröße-Breite", value: $currentJob.paperSize.width)
                        }
                        .onChange(of: currentJob.paperSize.width) { updateJob() }
                        
                        // Paper Size Height
                        HStack {
                            Text("Papiergröße-Höhe:")
                            Tools.doubleTextField(label: "Papiergröße-Höhe", value: $currentJob.paperSize.height)
                        }
                        .onChange(of: currentJob.paperSize.height) { updateJob() }
                        
                        HStack {
                            Text("Papiergröße-Orientierung")
                            Tools.doubleTextField(label: "Papiergröße-Orientierung", value: $currentJob.paperSize.orientation)
                        }
                        .onChange(of: currentJob.paperSize.orientation) { updateJob() }
                    }
                }

                CollapsibleSection(title: "Stift", systemImage: "pencil.tip") {
                    Text("Stift-Einstellungen folgen...")
                        .foregroundColor(.secondary)
                }

                CollapsibleSection(title: "Maschine", systemImage: "gearshape.2") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Origin X")
                            TextField("X", value: $currentJob.origin.x, formatter: NumberFormatter())
                        }
                        HStack {
                            Text("Origin Y")
                            TextField("Y", value: $currentJob.origin.y, formatter: NumberFormatter())
                        }
                        Toggle("Aktiv", isOn: $currentJob.isActive)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, showBottomBar ? 60 : 0)
        }
        .safeAreaInset(edge: .bottom) {
            if showBottomBar {
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
        }
    }
}

/*
 
 import SwiftUI
 import SVGView

 struct JobPreviewView: View {
     @Binding var goToStep: Int
     @Binding var currentJob: PlotJobData

     @EnvironmentObject var store: GenericStore<PlotJobData>
     @Environment(\.horizontalSizeClass) private var horizontalSizeClass

     @State private var zoom: Double = 1.0
     @State private var pitch: Double = 0.0
     @State private var origin: CGPoint = .zero
     @State private var svgFileName: String? = nil
     @State private var showingFileImporter = false
     @State private var selectedTab: Int = 0
     @State private var showSourcePreview: Bool = false

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
                                 store: store,
                                 showBottomBar: false
                             )
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
                                 store: store,
                                 showBottomBar: true
                             )
                             .padding(.horizontal, 12)
                             .frame(maxWidth: .infinity)
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
             Button {
                 print("Menübutton gedrückt")
             } label: {
                 Label("Beispiel", systemImage: "slider.horizontal.3")
             }
         }
         .padding()
         .background(.ultraThinMaterial)
     }

     @ViewBuilder
     var previewContent: some View {
         if showSourcePreview {
             PaperSourcePreview(job: currentJob)
                 .frame(maxWidth: .infinity, maxHeight: .infinity)
                 .clipped()
                 .padding(.horizontal)
         } else {
             PaperPreview(zoom: $zoom, pitch: $pitch, origin: $origin, job: currentJob)
                 .frame(maxWidth: .infinity, maxHeight: .infinity)
                 .clipped()
                 .padding(.horizontal)
         }
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

 struct SettingsPanel: View {
     @Binding var goToStep: Int
     @Binding var currentJob: PlotJobData
     @Binding var svgFileName: String?
     @Binding var showingFileImporter: Bool
     @Binding var showSourcePreview: Bool

     var store: GenericStore<PlotJobData>
     var showBottomBar: Bool = false

     var body: some View {
         ScrollView {
             VStack(alignment: .leading, spacing: 12) {
                 CollapsibleSection(title: "Job", systemImage: "doc.plaintext") {
                     VStack(alignment: .leading) {
                         TextField("Name", text: $currentJob.name)
                         TextField("Beschreibung", text: $currentJob.description)
                     }
                     .textFieldStyle(.roundedBorder)
                 }

                 CollapsibleSection(title: "SVG", systemImage: "photo") {
                     VStack(alignment: .leading) {
                         Toggle("Code-Ansicht anzeigen", isOn: $showSourcePreview)

                         if let name = svgFileName {
                             Text("Datei: \(name)")
                         } else {
                             Text("Keine SVG ausgewählt").foregroundColor(.secondary)
                         }

                         Button("SVG auswählen") {
                             showingFileImporter = true
                         }
                     }
                 }

                 CollapsibleSection(title: "Signatur", systemImage: "signature") {
                     Text("Signatur-Einstellungen folgen...")
                         .foregroundColor(.secondary)
                 }

                 CollapsibleSection(title: "Papier", systemImage: "doc.plaintext") {
                     VStack(alignment: .leading) {
                         TextField("Papier-Name", text: $currentJob.paperSize.name)
                         TextField("Breite", value: $currentJob.paperSize.width, formatter: NumberFormatter())
                         TextField("Höhe", value: $currentJob.paperSize.height, formatter: NumberFormatter())
                         TextField("Orientierung", value: $currentJob.paperSize.orientation, formatter: NumberFormatter())
                     }
                 }

                 CollapsibleSection(title: "Stift", systemImage: "pencil.tip") {
                     Text("Stift-Einstellungen folgen...")
                         .foregroundColor(.secondary)
                 }

                 CollapsibleSection(title: "Maschine", systemImage: "gearshape.2") {
                     VStack(alignment: .leading) {
                         HStack {
                             Text("Origin X")
                             TextField("X", value: $currentJob.origin.x, formatter: NumberFormatter())
                         }
                         HStack {
                             Text("Origin Y")
                             TextField("Y", value: $currentJob.origin.y, formatter: NumberFormatter())
                         }
                         Toggle("Aktiv", isOn: $currentJob.isActive)
                     }
                 }
             }
             .padding(.horizontal, 12)
             .padding(.bottom, showBottomBar ? 60 : 0)
         }
         .safeAreaInset(edge: .bottom) {
             if showBottomBar {
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
         }
     }
 }
 
 
 */










/* BACKUP
 
 
 import SwiftUI
 import SVGView
 
 struct JobPreviewView: View {
 @Binding var goToStep: Int
 @Binding var currentJob: PlotJobData
 
 @EnvironmentObject var store: GenericStore<PlotJobData>
 @Environment(\.horizontalSizeClass) private var horizontalSizeClass
 
 @State private var zoom: Double = 1.0
 @State private var pitch: Double = 0.0
 @State private var origin: CGPoint = .zero
 @State private var svgFileName: String? = nil
 @State private var showingFileImporter = false
 @State private var selectedTab: Int = 0
 
 var body: some View {
 GeometryReader { geometry in
 let isCompactLayout = horizontalSizeClass == .compact || geometry.size.width < 700
 
 Group {
 if isCompactLayout {
 // iPhone & schmale iPad-SplitView: Umschaltbare Ansicht
 VStack(spacing: 0) {
 Picker("Ansicht wählen", selection: $selectedTab) {
 Text("Einstellungen").tag(0)
 Text("Vorschau").tag(1)
 }
 .pickerStyle(.segmented)
 .padding()
 
 if selectedTab == 0 {
 SettingsPanel(goToStep: $goToStep, currentJob: $currentJob, svgFileName: $svgFileName, showingFileImporter: $showingFileImporter, store: store)
 } else {
 PaperPreview(zoom: $zoom, pitch: $pitch, origin: $origin, job: currentJob)
 .padding()
 }
 }
 } else {
 // iPad Landscape & macOS: klassisches SplitView ohne Titel
 NavigationSplitView {
 SettingsPanel(goToStep: $goToStep, currentJob: $currentJob, svgFileName: $svgFileName, showingFileImporter: $showingFileImporter, store: store)
 } detail: {
 PaperPreview(zoom: $zoom, pitch: $pitch, origin: $origin, job: currentJob)
 .frame(maxWidth: .infinity, maxHeight: .infinity)
 .clipped()
 .padding(.horizontal)
 }
 }
 }
 .onAppear {
 loadActiveJob()
 }
 }
 }
 
 private func loadActiveJob() {
 svgFileName = URL(fileURLWithPath: currentJob.svgFilePath).lastPathComponent
 }
 }
 
 struct SettingsPanel: View {
 @Binding var goToStep: Int
 @Binding var currentJob: PlotJobData
 @Binding var svgFileName: String?
 @Binding var showingFileImporter: Bool
 
 var store: GenericStore<PlotJobData>
 
 var body: some View {
 ScrollView {
 VStack(alignment: .leading, spacing: 12) {
 CollapsibleSection(title: "Projekt") {
 VStack(alignment: .leading, spacing: 10) {
 // Job Name
 HStack {
 Text("Name:")
 Tools.textField(label: "Job Name", value: $currentJob.name)
 }
 .onChange(of: currentJob.name) { updateJob() }
 
 // Job Description
 HStack {
 Text("Beschreibung:")
 Tools.textField(label: "Beschreibung", value: $currentJob.description)
 }
 .onChange(of: currentJob.description) { updateJob() }
 }
 
 }
 CollapsibleSection(title: "SVG-Properties") {
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
 .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.svg]) { result in
 switch result {
 case .success(let url):
 handleFileSelection(url)
 case .failure(let error):
 print("Fehler beim Auswählen der Datei: \(error.localizedDescription)")
 }
 }
 }
 
 // Property editor for editing job properties
 SvgPropertyEditorView(currentJob: $currentJob)
 }
 
 CollapsibleSection(title: "Paper-Settings") {
 VStack(alignment: .leading, spacing: 10) {
 // Paper Size
 HStack {
 Text("Papiergröße-Name")
 Tools.textField(label: "Papiergröße-Name", value: $currentJob.paperSize.name)
 }
 .onChange(of: currentJob.paperSize.name) { updateJob() }
 
 // Paper Size Width
 HStack {
 Text("Papiergröße-Breite:")
 Tools.doubleTextField(label: "Papiergröße-Breite", value: $currentJob.paperSize.width)
 }
 .onChange(of: currentJob.paperSize.width) { updateJob() }
 
 // Paper Size Height
 HStack {
 Text("Papiergröße-Höhe:")
 Tools.doubleTextField(label: "Papiergröße-Höhe", value: $currentJob.paperSize.height)
 }
 .onChange(of: currentJob.paperSize.height) { updateJob() }
 
 HStack {
 Text("Papiergröße-Orientierung")
 Tools.doubleTextField(label: "Papiergröße-Orientierung", value: $currentJob.paperSize.orientation)
 }
 .onChange(of: currentJob.paperSize.orientation) { updateJob() }
 }
 }
 
 CollapsibleSection(title: "Pen-Settings") {
 VStack(alignment: .leading, spacing: 10) {
 Text("Stift-Einstellungen hier")
 .foregroundColor(.secondary)
 }
 }
 
 CollapsibleSection(title: "Machines") {
 VStack(alignment: .leading, spacing: 10) {
 // Origin (X, Y)
 HStack {
 Text("Origin:")
 Tools.CGFloatTextField(label: "X", value: $currentJob.origin.x)
 Tools.CGFloatTextField(label: "Y", value: $currentJob.origin.y)
 }
 .onChange(of: currentJob.origin.x) { updateJob() }
 .onChange(of: currentJob.origin.y) { updateJob() }
 
 // Active state
 HStack {
 Text("Aktiv:")
 Toggle(isOn: $currentJob.isActive) {
 Text("Aktivieren")
 }
 }
 .onChange(of: currentJob.isActive) { updateJob() }
 }}
 
 Spacer(minLength: 20)
 }
 .padding()
 }
 .safeAreaInset(edge: .bottom) {
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
 }
 
 private func handleFileSelection(_ url: URL) {
 guard url.startAccessingSecurityScopedResource() else {
 print("No permission to access the resource")
 return
 }
 
 defer {
 url.stopAccessingSecurityScopedResource()
 }
 
 let fileManager = FileManager.default
 let destinationURL = getSVGDirectory().appendingPathComponent(url.lastPathComponent)
 
 do {
 if fileManager.fileExists(atPath: destinationURL.path) {
 try fileManager.removeItem(at: destinationURL)
 }
 
 currentJob.svgFilePath = destinationURL.path
 svgFileName = destinationURL.lastPathComponent
 
 Task {
 await store.save(item: currentJob, fileName: currentJob.id.uuidString)
 }
 
 try fileManager.copyItem(at: url, to: destinationURL)
 
 } catch {
 print("Fehler beim Kopieren der Datei: \(error.localizedDescription)")
 }
 }
 
 private func getSVGDirectory() -> URL {
 let fileManager = FileManager.default
 let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
 let svgDirectory = directory.appendingPathComponent("svgs")
 
 if !fileManager.fileExists(atPath: svgDirectory.path) {
 do {
 try fileManager.createDirectory(at: svgDirectory, withIntermediateDirectories: true)
 } catch {
 print("Fehler beim Erstellen des Verzeichnisses: \(error.localizedDescription)")
 }
 }
 
 return svgDirectory
 }
 
 private func updateJob() {
 // Speichern der Änderungen
 Task {
 await store.save(item: currentJob, fileName: currentJob.id.uuidString)
 }
 }
 }
 
 struct CollapsibleSection<Content: View>: View {
 let title: String
 @ViewBuilder let content: Content
 
 @State private var isExpanded = true
 
 var body: some View {
 VStack(alignment: .leading, spacing: 8) {
 Button(action: { isExpanded.toggle() }) {
 HStack {
 Text(title)
 .font(.headline)
 .padding(6)
 .background(Color.gray.opacity(0.2))
 .cornerRadius(6)
 Spacer()
 Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
 }
 .foregroundColor(.primary)
 }
 
 if isExpanded {
 content
 .padding(.leading, 8)
 }
 }
 .padding(.vertical, 6)
 }
 }
 
 */
/*
 #Preview("iPhone") {
 JobPreviewView(
 goToStep: .constant(2),
 currentJob: .constant(PlotJobData.sample)
 )
 .environmentObject(GenericStore<PlotJobData>())
 .previewDevice("iPhone 15 Pro")
 }
 
 #Preview("iPad") {
 JobPreviewView(
 goToStep: .constant(2),
 currentJob: .constant(PlotJobData.sample)
 )
 .environmentObject(GenericStore<PlotJobData>())
 .previewDevice("iPad Pro (11-inch) (5th generation)")
 }
 
 #Preview("macOS") {
 JobPreviewView(
 goToStep: .constant(2),
 currentJob: .constant(PlotJobData.sample)
 )
 .environmentObject(GenericStore<PlotJobData>())
 .frame(width: 1200, height: 800)
 }
 */
