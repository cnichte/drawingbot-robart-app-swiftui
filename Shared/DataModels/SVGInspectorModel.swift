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
    @Published var job: JobData {
        didSet {
            jobBox = JobBox(from: job)
        }
    }
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
    init(job: JobData, machine: MachineData? = nil) {
        self.job = job
        self.jobBox = JobBox(from: job)
        self.machine = machine ?? job.selectedMachine
    }
    
    func syncJobBoxBack() {
        self.job = jobBox.toJobData()
    }
    
        // MARK: - Bindings
        func binding<Value>(_ keyPath: WritableKeyPath<JobData, Value>) -> Binding<Value> {
            Binding<Value>(
                get: { self.job[keyPath: keyPath] },
                set: { newValue in
                    var updated = self.job
                    updated[keyPath: keyPath] = newValue
                    self.job = updated
                }
            )
        }

        func bindingSignature<Value>(
            _ keyPath: WritableKeyPath<SignatureData, Value>,
            defaultValue: @escaping () -> SignatureData
        ) -> Binding<Value> {
            Binding<Value>(
                get: {
                    if self.job.signatur == nil {
                        self.job.signatur = defaultValue() // TODO: Publishing changes from within view updates is not allowed, this will cause undefined behavior.
                    }
                    return self.job.signatur![keyPath: keyPath]
                },
                set: { newValue in
                    if self.job.signatur == nil {
                        self.job.signatur = defaultValue()
                    }
                    var signature = self.job.signatur!
                    signature[keyPath: keyPath] = newValue
                    self.job.signatur = signature
                }
            )
        }

        func bindingForJob() -> Binding<JobData> {
            Binding<JobData>(
                get: { self.job },
                set: { self.job = $0 }
            )
        }

    // MARK: - SVG laden & parsen
    func loadAndParseSVG(
        svgSize: CGSize = CGSize(width: 500, height: 500),
        paperSize: CGSize = CGSize(width: 210, height: 297)
    ) async {
        let url = JobsDataFileManager.shared.workingSVGURL(for: job.id)

        guard FileManager.default.fileExists(atPath: url.path) else {
            appLog(.error, "Arbeitskopie nicht gefunden: \(url)")
            return
        }

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

    // MARK: - Speichern
    func save(using store: GenericStore<JobData>) async {
        let syncedJob = jobBox.toJobData()
        appLog(.error, "🧪 SAVE NAME:", syncedJob.name)
        appLog(.error, "🧪 SAVE DESC:", syncedJob.description)
        await store.save(item: syncedJob, fileName: syncedJob.id.uuidString)
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

// MARK: - bindingForPenSlot

extension SVGInspectorModel {
    func bindingForPenSlot(at index: Int) -> Binding<PenConfiguration> {
        Binding<PenConfiguration>(
            get: {
                if index < self.job.penConfiguration.count {
                    return self.job.penConfiguration[index]
                } else {
                    return PenConfiguration(penSVGLayerAssignment: .toLayer, color: "", layer: "", angle: 90)
                }
            },
            set: { newValue in
                if index < self.job.penConfiguration.count {
                    self.job.penConfiguration[index] = newValue
                }
            }
        )
    }
}
