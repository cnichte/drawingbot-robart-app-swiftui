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
    
    var penID: UUID? = nil               // <-- neu: ausgewählter Stift aus PenData
    var penColorID: UUID? = nil          // <-- neu: Farbe aus dem Stift aus PenData
    var penVarianteID: UUID? = nil       // <-- neu: Variante aus dem Stift aus PenData
    
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
    var paperData: PaperData
    var paperDataID: UUID? = nil // für Picker-Anbindung
    var paperOrientation:PaperOrientation = .portrait
    
    // svg
    var svgFilePath: String
    
    var angle: Double
    var zoom: Double
    
    var origin: CGPoint
    
    // pen
    var penConfiguration: [PenConfiguration]
    var penConfigurationIDs: [UUID?] = [] // Für Picker-Anbindung
    // TODO: var pens: PenData
    
    // machine -> cgode, egg
    var machineData: MachineData
    var machineDataID: UUID? = nil // für Picker-Anbindung
    var currentCommandIndex: Int
    
    // signatur
    var signaturData: SignatureData?
    
    // job is running
    var isActive: Bool = false
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        
        svgFilePath: String = "",
        currentCommandIndex: Int = 0,
        angle: Double = 0,
        zoom: Double = 1.0,
        origin: CGPoint = .zero,
        penConfiguration: [PenConfiguration] = [],
        penConfigurationIDs: [UUID?] = [],
        
        machineData: MachineData,
        machineDataID: UUID? = nil,
        
        paperData: PaperData,
        paperDataID: UUID? = nil,
        
        paperOrientation: PaperOrientation = .portrait,
        signatur: SignatureData? = nil,
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        
        self.svgFilePath = svgFilePath
        self.angle = angle
        self.zoom = zoom
        self.origin = origin
        
        self.machineData = machineData
        self.machineDataID = machineDataID ?? machineData.id
        
        self.penConfiguration = penConfiguration
        self.penConfigurationIDs = penConfigurationIDs.isEmpty ? penConfiguration.map { $0.penID } : penConfigurationIDs // NEU: Setze penConfigurationIDs basierend auf penID
        self.currentCommandIndex = currentCommandIndex
        
        self.paperData = paperData
        self.paperDataID = paperDataID ?? paperData.id // Setze paperFormatID auf paper.id, falls nil
        self.paperOrientation = paperOrientation
        
        self.signaturData = signatur
        
        self.isActive = isActive
        
        // Setze penConfigurationIDs basierend auf penConfiguration.penID
        self.penConfigurationIDs = penConfigurationIDs.isEmpty ? penConfiguration.map { $0.penID } : penConfigurationIDs
        
        // Validiere Konsistenz zwischen penConfiguration und penConfigurationIDs
        if penConfiguration.count != penConfigurationIDs.count {
            self.penConfigurationIDs = Array(repeating: nil, count: penConfiguration.count)
            for index in 0..<min(penConfiguration.count, penConfigurationIDs.count) {
                self.penConfigurationIDs[index] = penConfiguration[index].penID
            }
        }
    }
    
    static var `default`: JobData {
        JobData(id: UUID.force("cfd1401b-af1a-4382-a101-cee156f1cda4"), name: "Kein Job", machineData: .default, paperData: .default)
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
