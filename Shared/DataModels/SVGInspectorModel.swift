//
//  SVGInspectorModel.swift
//  Robart
//
//  Created by Carsten Nichte on 22.05.25.
//

// SVGInspectorModel.swift
import Foundation
import SwiftUI

@MainActor
final class SVGInspectorModel: ObservableObject {
    // MARK: - Eingaben
    @Published var job: JobData
    @Published var jobBox: JobBox
    @Published var machine: MachineData?
    
    // MARK: - Parser-Ergebnisse
    @Published var allElements: [ParserListItem] = []
    @Published var layers: [SVGLayer] = []
    @Published var elementsInSelectedLayer: [ParserListItem] = []
    
    // MARK: - Auswahlstatus
    @Published var selectedLayer: SVGLayer? {
        didSet { updateElementsForSelectedLayer() }
    }
    
    @Published var selectedElement: ParserListItem? {
        didSet { updatePropertiesForSelectedElement() }
    }
    
    @Published var selectedProperties: [SVGProperty] = []
    
    // MARK: - Init
    init(job: JobData, machine: MachineData? = nil, pensStore: GenericStore<PenData>? = nil) {
        self.job = job
        self.jobBox = JobBox(from: job)
        self.machine = machine ?? job.machineData

        // appLog(.info, "Initializing SVGInspectorModel with pensStore: \(pensStore != nil ? "available" : "nil")")
        
        // Validiere penConfigurationIDs beim Laden
        if let pensStore = pensStore {
            let validPenIDs = Set(pensStore.items.map { $0.id })
            var updatedConfigs = self.jobBox.penConfiguration
            var updatedIDs = self.jobBox.penConfigurationIDs
            
            // Validiere und bereinige penConfigurationIDs
            updatedIDs = updatedIDs.map { id in
                if let id = id, validPenIDs.contains(id) {
                    return id
                } else {
                    // appLog(.warning, "Invalid penID on init: \(id?.uuidString ?? "nil"), resetting to nil")
                    return nil
                }
            }
            
            // Synchronisiere penConfiguration.penID
            for index in 0..<min(updatedConfigs.count, updatedIDs.count) {
                updatedConfigs[index].penID = updatedIDs[index]
            }
            
            // Stelle sicher, dass die Länge konsistent ist
            if updatedConfigs.count != updatedIDs.count {
                updatedIDs = Array(repeating: nil, count: updatedConfigs.count)
                for index in 0..<min(updatedConfigs.count, updatedIDs.count) {
                    updatedIDs[index] = updatedConfigs[index].penID
                }
            }
            
            self.jobBox.penConfiguration = updatedConfigs
            self.jobBox.penConfigurationIDs = updatedIDs
            // appLog(.info, "Synchronized penConfiguration on init: \(updatedConfigs.map { "penID=\($0.penID?.uuidString ?? "nil")" })")
            // appLog(.info, "Synchronized penConfigurationIDs on init: \(updatedIDs.map { $0?.uuidString ?? "nil" })")
            
            self.job = jobBox.toJobData()
        }
        
    }
    
    // Manuelle Synchronisation
    func syncJobBox() {
        self.jobBox = JobBox(from: job)
    }
    
    func syncJobBoxBack() {
        self.job = jobBox.toJobData()
    }
    
    // MARK: - Speichern
    func save(using store: GenericStore<JobData>) async {
        self.syncJobBoxBack() // Stelle sicher, dass jobBox und job synchron sind
        let syncedJob = jobBox.toJobData()
        await store.save(item: syncedJob, fileName: syncedJob.id.uuidString)
    }
    
    // MARK: - SVG laden & parsen
    func loadAndParseSVG(
        svgSize: CGSize = CGSize(width: 500, height: 500),
        paperSize: CGSize = CGSize(width: 210, height: 297)
    ) async {
        
        appLog(.info, "Starting loadAndParseSVG, job.svgFilePath: \(job.svgFilePath), jobID: \(job.id.uuidString)")
                
        let url = JobsDataFileManager.shared.workingSVGURL(for: job.id)
        appLog(.info, "Generated SVG URL: \(url.path), machine: \(machine?.name ?? "default")")
        
        guard !job.svgFilePath.isEmpty else {
            appLog(.error, "No SVG file path provided in job")
            return
        }
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            appLog(.error, "Arbeitskopie nicht gefunden: \(url)")
            return
        }
        
        appLog(.info, "Attempting to parse SVG at URL: \(url.path)")
        let parser = SVGParser(generator: GCodeGenerator(machineData: machine ?? .default))
        let ok = parser.loadSVGFile(
            from: url,
            svgWidth: svgSize.width,
            svgHeight: svgSize.height,
            paperWidth: paperSize.width,
            paperHeight: paperSize.height
        )
        
        if ok {
            allElements = parser.elements
            groupElementsByLayer()
            appLog(.info, "SVG parsing successful, found \(allElements.count) elements, \(layers.count) layers")
        } else {
            appLog(.error, "Failed to parse SVG at: \(url.path)")
        }
    }
    
    // MARK: - Gruppieren nach Layer
    private func groupElementsByLayer() {
        let grouped = Dictionary(grouping: allElements) { item in
            item.element.rawAttributes["inkscape:label"] ?? "ohne Ebene"
        }
        
        layers = grouped.keys.sorted().map { SVGLayer(name: $0) }
        selectedLayer = layers.first
    }
    
    private func updateElementsForSelectedLayer() {
        guard let name = selectedLayer?.name else {
            elementsInSelectedLayer = []
            return
        }
        elementsInSelectedLayer = allElements.filter {
            ($0.element.rawAttributes["inkscape:label"] ?? "ohne Ebene") == name
        }
    }
    
    private func updatePropertiesForSelectedElement() {
        guard let el = selectedElement else {
            selectedProperties = []
            return
        }
        
        selectedProperties = el.element.rawAttributes.map { key, value in
            SVGProperty(key: key, value: value)
        }
    }
    
    // MARK: - GCode Hilfsfunktionen
    func gcodeForSelectedElement() -> String {
        selectedElement?.output ?? ""
    }
    
    func gcodeForCurrentLayer() -> String {
        elementsInSelectedLayer.map(\.output).joined(separator: "\n")
    }
    
    func gcodeForAllElements() -> String {
        allElements.map(\.output).joined(separator: "\n")
    }
}
