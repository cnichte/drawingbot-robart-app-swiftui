//
//  JobSummaryView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.
//

// JobSummaryView.swift
import SwiftUI

struct JobSummaryView: View {
    @Binding var goToStep: Int
    @Binding var currentJob: JobData
    @EnvironmentObject var store: GenericStore<JobData>
    
    private let paperWidth = 210.0
    private let paperHeight = 297.0
    private let svgWidth = 500.0
    private let svgHeight = 500.0
    
    private let svgFileURL: URL
    private var parser: SVGParser<GCodeGenerator>
    
    @State private var gCode: String = ""
    @State private var errorMessage: String? = nil
    @State private var selectedElement: ParserListItem? = nil
    @State private var elements: [ParserListItem] = []  // Sammlung von ParserListItem-Objekten
    
    init(goToStep: Binding<Int>, currentJob: Binding<JobData>) {
        _goToStep = goToStep
        _currentJob = currentJob
        
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let svgDirectory = documentDirectory.appendingPathComponent("svgs")
        self.svgFileURL = svgDirectory.appendingPathComponent("svg-example.svg")
        self.parser = SVGParser(generator: GCodeGenerator())
        // self.parser = SVGtoGCodeParser(paperWidth: paperWidth, paperHeight: paperHeight, svgWidth: svgWidth, svgHeight: svgHeight)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // 1. Zeige die Liste der SVG-Elemente (links)
            HStack {
                VStack {
                    Text("SVG-Elemente")
                    List(elements, id: \.id, selection: $selectedElement) { item in
                        Button(action: {
                            selectedElement = item
                            gCode = item.output  // Zeige G-Code für das ausgewählte Element
                        }) {
                            Text(item.element.name)  // Zeige den Namen des SVG-Elements
                        }
                    }
                    .onAppear {
                        loadAndParseSVG() // Sicherstellen, dass SVG beim Anzeigen des Views geladen wird
                    }
                }
                
                // 2. Zeige den G-Code für das ausgewählte Element oder für alle Elemente (rechts)
                VStack {
                    if let selectedElement = selectedElement {
                        ScrollView {
                            Text("G-Code für: \(selectedElement.element.name)\n\n\(gCode)")
                                .padding()
                                .font(.system(size: 12, weight: .light, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        ScrollView {
                            Text("G-Code für alle Elemente:\n\n\(gCode)")
                                .padding()
                                .font(.system(size: 12, weight: .light, design: .monospaced))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            
            // Job Zusammenfassung
            VStack(alignment: .leading) {
                Text("📋 Zusammenfassung")
                    .font(.title2)
                Text("Job Name: \(currentJob.name)")
                    .font(.headline)
                Text("Papiergröße: \(currentJob.paper.paperFormat.name) - \(currentJob.paper.paperFormat.width) x \(currentJob.paper.paperFormat.height) mm")
                Text("Beschreibung: \(currentJob.description)")
                
                Button("Drucken starten") {
                    Task {
                        await store.save(item: currentJob, fileName: currentJob.id.uuidString)
                    }
                }
                .padding()
                .foregroundColor(.green)
            }
            
            HStack {
                Button("◀︎ Zurück") {
                    goToStep = 2
                }
                Spacer()
                Button("Schließen ✕") {
                    goToStep = 1
                }
            }
        }
        .padding()
        .navigationTitle("SVG zu G-Code")
    }
    
    private func loadAndParseSVG() {
        // Wenn das SVG geladen wurde, überprüfe, ob die Elemente gesetzt sind
        let okay = parser.loadSVGFile(from: svgFileURL, svgWidth: 600, svgHeight: 600, paperWidth: 600, paperHeight: 600)  // Keine if-let nötig
        elements = parser.elements  // Angenommen, parser.elements ist ein Array von ParserListItem
        gCode = parser.elements.map { $0.output }.joined(separator: "\n")
        
        // Debug-Ausgabe, um sicherzustellen, dass die Elemente geladen sind
        appLog(.info, "Geladene Elemente: \(elements.count)")
    }
}
// G-Code Vorlagen in einer map speichern: [{ svgElement:string, gcodeTemplates[ {"key":"value"}] }]
// Die Map in den Settigs speichern.
// und ne decription dazu.


