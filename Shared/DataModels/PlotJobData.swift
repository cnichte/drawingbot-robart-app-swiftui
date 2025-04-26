//
//  PlotJob.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.
//

//  PlotJob.swift
import SwiftUI
import Foundation
import UniformTypeIdentifiers

extension UTType {
    // Type "de.nichte.plotjob" was expected to be declared and exported in the Info.plist of Robart.app, but it was not found.
    static let plotJob = UTType(exportedAs: "de.nichte.plotjob")
}



struct PlotJobData: Identifiable, Codable, Equatable, Transferable {
    let id: UUID
    var name: String
    var description: String
    // alt. noch zu überarbeiten
    var paperSize: PaperSize
    var svgFilePath: String
    var gcodeCommands: [String]
    var currentCommandIndex: Int
    var pitch: Double
    var zoom: Double
    var origin: CGPoint
    var penSettings: [PenConfiguration]
    var isActive: Bool = false
    
    var paperFormatID: UUID? = nil // <-- NEU für Picker-Anbindung
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        paperSize: PaperSize,
        svgFilePath: String = "",
        gcodeCommands: [String] = [],
        currentCommandIndex: Int = 0,
        pitch: Double = 0,
        zoom: Double = 1.0,
        origin: CGPoint = .zero,
        penSettings: [PenConfiguration] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.paperSize = paperSize
        self.svgFilePath = svgFilePath
        self.gcodeCommands = gcodeCommands
        self.currentCommandIndex = currentCommandIndex
        self.pitch = pitch
        self.zoom = zoom
        self.origin = origin
        self.penSettings = penSettings
    }
    
    // Custom UTI for Drag and Drop
    static let customUTI = UTType(exportedAs: "de.nichte.plotjob") // TODO: de.nichte.robart.plotjob
    
    public static var transferRepresentation: some TransferRepresentation {
         CodableRepresentation(contentType: .plotJob)
     }
}

struct PenConfiguration: Codable, Equatable, Identifiable {
    var id = UUID()
    var color: String
    var layer: String
    var angle: Int // 45° oder 90°
}

struct PaperSize: Codable, Equatable, Identifiable, Hashable {
    var id = UUID()
    var name: String
    var width: Double
    var height: Double
    var orientation: Double
    var note: String?
}
