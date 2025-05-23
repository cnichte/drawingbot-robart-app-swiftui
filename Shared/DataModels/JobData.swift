//
//  JobData.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.
//

// JobData.swift
import SwiftUI
import Foundation
import UniformTypeIdentifiers
 
extension UTType {
    // Type "de.nichte.plotjob" was expected to be declared and exported in the Info.plist of Robart.app, but it was not found.
    static let plotJob = UTType(exportedAs: "de.nichte.plotjob")
}

enum PaperOrientation: String, Codable {
    case landscape = ".landscape"
    case portrait = ".portrait"
}

enum PenSVGLayerAssignment: String, Codable {
    case toColor = ".toColor"
    case toLayer = ".toLayer" 
}

struct PenConfiguration: Codable, Equatable, Identifiable {
    var id = UUID()
    var penSVGLayerAssignment:PenSVGLayerAssignment
    
    var penID: UUID? = nil               // <-- neu: ausgewählter Stift
    var penColorID: UUID? = nil          // <-- neu: Farbe aus dem Stift
    var penVarianteID: UUID? = nil       // <-- neu: Variante aus dem Stift
    
    var color: String // Ein Stift kann einer Farbe im SVG zugeordnet werden
    var layer: String // oder einer Ebene (Element g) zugeordnet werden.
    var angle: Int // 45° oder 90°
    // TODO: Vielleicht noch wie weit er rauf oder runter gefahren werden soll.
}


struct JobData: Identifiable, Codable, Equatable, Transferable, Hashable, Defaultable  {
    // standards
    let id: UUID
    var name: String
    var description: String
    
    // paper
    var paper: PaperData
    var paperFormatID: UUID? = nil // <-- NEU für Picker-Anbindung
    var paperOrientation:PaperOrientation = .portrait
    
    // svg
    var svgFilePath: String
    var pitch: Double
    var zoom: Double
    var origin: CGPoint
    
    // pen
    var penConfiguration: [PenConfiguration]
    // TODO: var pens: PenData
    
    // machine -> cgode, egg
    var selectedMachine: MachineData
    var currentCommandIndex: Int
    
    // signatur
    var signatur: SignatureData?
    
    // job is running
    var isActive: Bool = false
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        paper: PaperData,
        svgFilePath: String = "",
        currentCommandIndex: Int = 0,
        pitch: Double = 0,
        zoom: Double = 1.0,
        origin: CGPoint = .zero,
        penConfiguration: [PenConfiguration] = [],
        selectedMachine: MachineData,
        paperFormatID: UUID? = nil,
        paperOrientation: PaperOrientation = .portrait,
        signatur: SignatureData? = nil,
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.paper = paper
        self.svgFilePath = svgFilePath
        self.currentCommandIndex = currentCommandIndex
        self.pitch = pitch
        self.zoom = zoom
        self.origin = origin
        self.penConfiguration = penConfiguration
        self.selectedMachine = selectedMachine
        self.paperFormatID = paperFormatID
        self.paperOrientation = paperOrientation
        self.signatur = signatur
        self.isActive = isActive
    }
    
    static var `default`: JobData {
        JobData(id: UUID.force("cfd1401b-af1a-4382-a101-cee156f1cda4"), name: "Kein Job", paper: .default, selectedMachine: .default)
    }
    
    static func == (lhs: JobData, rhs: JobData) -> Bool {
        lhs.id == rhs.id // oder vollständiger Vergleich
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    
    // Custom UTI for Drag and Drop
    static let customUTI = UTType(exportedAs: "de.nichte.plotjob") // TODO: de.nichte.robart.plotjob
    
    public static var transferRepresentation: some TransferRepresentation {
         CodableRepresentation(contentType: .plotJob)
     }
}
