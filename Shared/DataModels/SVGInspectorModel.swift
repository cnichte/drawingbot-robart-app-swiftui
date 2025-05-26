//
//  SVGInspectorModel.swift
//  Robart
//
//  Created by Carsten Nichte on 22.05.25.
//

// SVGInspectorModel.swift - Korrigierte Version ohne Endlosschleife
import Foundation
import SwiftUI

@MainActor
final class SVGInspectorModel: ObservableObject {
    // MARK: - Eingaben
    @Published var job: JobData
    @Published var jobBox: JobBox
    
    // Zentrale Maschinenreferenz - OHNE didSet um Endlosschleifen zu vermeiden
    @Published var machine: MachineData?
    
    // MARK: - Parser-Ergebnisse
    @Published var allElements: [ParserListItem] = []
    @Published var layers: [SVGLayer] = []
    @Published var elementsInSelectedLayer: [ParserListItem] = []
    
    // MARK: - Auswahlstatus
    @Published var selectedLayer: SVGLayer? {
        didSet {
            Task { @MainActor in
                updateElementsForSelectedLayer()
            }
        }
    }
    
    @Published var selectedElement: ParserListItem? {
        didSet {
            Task { @MainActor in
                updatePropertiesForSelectedElement()
            }
        }
    }
    
    @Published var selectedProperties: [SVGProperty] = []
    
    // Flag to prevent multiple concurrent parsing operations
    private var isParsingInProgress = false
    
    // MARK: - Init
    init(job: JobData, machine: MachineData? = nil, pensStore: GenericStore<PenData>? = nil) {
        self.job = job
        self.jobBox = JobBox(from: job)
        self.machine = machine ?? job.machineData
        
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
            self.job = jobBox.toJobData()
        }
    }
    
    // MARK: - Machine Management
    func updateMachine(_ newMachine: MachineData?) {
        appLog(.info, "updateMachine called with: \(newMachine?.name ?? "nil")")
        
        // Prüfe ob sich die Maschine wirklich geändert hat
        guard newMachine?.id != machine?.id else {
            appLog(.info, "Machine unchanged, skipping update")
            return
        }
        
        // Aktualisiere alle Maschinenreferenzen OHNE didSet zu triggern
        self.machine = newMachine
        
        if let newMachine = newMachine {
            jobBox.machineData = newMachine
            jobBox.machineDataID = newMachine.id
        }
        
        // Trigger SVG parsing explizit
        Task { @MainActor in
            appLog(.info, "Triggering SVG parse for machine: \(newMachine?.name ?? "nil")")
            await loadAndParseSVG()
        }
    }
    
    // Manuelle Synchronisation
    func syncJobBox() {
        self.jobBox = JobBox(from: job)
        // Synchronisiere auch die Maschine OHNE updateMachine zu rufen
        let jobMachine = job.machineData
        if self.machine?.id != jobMachine.id {
            self.machine = jobMachine
        }
    }
    
    func syncJobBoxBack() {
        self.job = jobBox.toJobData()
        // Stelle sicher, dass machine auch synchron ist
        if let machine = self.machine {
            self.job.machineData = machine
            self.job.machineDataID = machine.id
        }
    }
    
    // MARK: - Speichern
    func save(using store: GenericStore<JobData>) async {
        self.syncJobBoxBack()
        let syncedJob = jobBox.toJobData()
        await store.save(item: syncedJob, fileName: syncedJob.id.uuidString)
    }
    
    // MARK: - SVG laden & parsen
    func loadAndParseSVG(
        svgSize: CGSize = CGSize(width: 500, height: 500),
        paperSize: CGSize = CGSize(width: 210, height: 297)
    ) async {
        
        // Prevent concurrent parsing operations
        guard !isParsingInProgress else {
            appLog(.info, "SVG parsing already in progress, skipping")
            return
        }
        
        isParsingInProgress = true
        defer { isParsingInProgress = false }
        
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
        
        // Parser-Aufruf auf Background Thread
        let parseResult = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let ok = parser.loadSVGFile( // Capture of 'parser' with non-sendable type 'SVGParser<GCodeGenerator>' in a '@Sendable' closure
                    from: url,
                    svgWidth: svgSize.width,
                    svgHeight: svgSize.height,
                    paperWidth: paperSize.width,
                    paperHeight: paperSize.height
                )
                continuation.resume(returning: (ok, parser.elements))
            }
        }
        
        // UI-Updates auf Main Thread
        if parseResult.0 {
            self.allElements = parseResult.1
            self.groupElementsByLayer()
            appLog(.info, "SVG parsing successful, found \(allElements.count) elements, \(layers.count) layers")
        } else {
            // Reset bei Fehler
            self.allElements = []
            self.layers = []
            self.elementsInSelectedLayer = []
            self.selectedLayer = nil
            self.selectedElement = nil
            self.selectedProperties = []
            appLog(.error, "Failed to parse SVG at: \(url.path)")
        }
    }
    
    // MARK: - Gruppieren nach Layer
    private func groupElementsByLayer() {
        let grouped = Dictionary(grouping: allElements) { item in
            item.element.rawAttributes["inkscape:label"] ?? "ohne Ebene"
        }
        
        let newLayers = grouped.keys.sorted().map { SVGLayer(name: $0) }
        
        // Nur updaten wenn sich etwas geändert hat
        if newLayers.map(\.name) != layers.map(\.name) {
            layers = newLayers
            selectedLayer = layers.first
            appLog(.info, "Layers grouped: \(layers.map(\.name))")
        }
    }
    
    private func updateElementsForSelectedLayer() {
        guard let name = selectedLayer?.name else {
            elementsInSelectedLayer = []
            return
        }
        let newElements = allElements.filter {
            ($0.element.rawAttributes["inkscape:label"] ?? "ohne Ebene") == name
        }
        
        if newElements.map(\.id) != elementsInSelectedLayer.map(\.id) {
            elementsInSelectedLayer = newElements
            appLog(.info, "Elements updated for layer '\(name)': \(newElements.count) elements")
        }
    }
    
    private func updatePropertiesForSelectedElement() {
        guard let el = selectedElement else {
            selectedProperties = []
            return
        }
        
        let newProperties = el.element.rawAttributes.map { key, value in
            SVGProperty(key: key, value: value)
        }
        
        selectedProperties = newProperties
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
