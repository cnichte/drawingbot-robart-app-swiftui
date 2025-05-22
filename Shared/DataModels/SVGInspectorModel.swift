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
    let job: JobData
    let machine: MachineData?
    
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
    init(job: JobData, machine: MachineData?) {
        self.job = job
        self.machine = machine
    }

    // MARK: - SVG laden & parsen
    func loadAndParseSVG(svgSize: CGSize = CGSize(width: 500, height: 500), paperSize: CGSize = CGSize(width: 210, height: 297)) async {
        let url = JobsDataFileManager.shared.workingSVGURL(for: job.id)

        guard FileManager.default.fileExists(atPath: url.path) else {
            appLog(.error, "Arbeitskopie nicht gefunden: \(url)")
            return
        }

        appLog(.error,  "⚙️ Verwende Maschine:", machine?.name ?? "nil")
        appLog(.error, "⚙️ Commands:", machine?.commandItems.map { $0.name } ?? [])
        
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
        } else {
            appLog(.error, "Fehler beim Parsen der SVG")
        }
    }

    // MARK: - Gruppieren nach Layer
    private func groupElementsByLayer() {
        let grouped = Dictionary(grouping: allElements) { item in
            item.element.rawAttributes["inkscape:label"] ?? "ohne Ebene"
        }

        layers = grouped.keys.sorted().map { SVGLayer(name: $0) }

        if let first = layers.first {
            selectedLayer = first
        }
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

    // MARK: - Hilfsfunktionen
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
