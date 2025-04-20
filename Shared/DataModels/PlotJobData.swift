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
    var paperSize: PaperSize
    var svgFilePath: String
    var gcodeCommands: [String]
    var currentCommandIndex: Int
    var pitch: Double
    var zoom: Double
    var origin: CGPoint
    var penSettings: [PenConfiguration]
    var isActive: Bool = false

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
    
    // Custom UTI
    static let customUTI = UTType(exportedAs: "de.nichte.plotjob")
    
    public static var transferRepresentation: some TransferRepresentation {
         CodableRepresentation(contentType: .plotJob)
     }
    
    // Conform to Transferable
    /*
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .plainText) { (value: PlotJobData) -> Data in
            try JSONEncoder().encode(value)
        } importing: { (data: Data) -> PlotJobData? in
            try JSONDecoder().decode(PlotJobData.self, from: data)
        }
    }
    */
}



/*

 // Conform to Transferable
 static var transferRepresentation: some TransferRepresentation {
     DataRepresentation(contentType: .plainText) { (value: PlotJobData) -> Data in
         try JSONEncoder().encode(value)
     } importing: { (data: Data) -> PlotJobData? in
         try JSONDecoder().decode(PlotJobData.self, from: data)
     }
 }
 
extension UTType {
    static let plotJob = UTType(exportedAs: "com.yourapp.plotjob")
}

extension PlotJobData: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .plotJob)
    }
}


struct PlotJobData: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var paperSize: PaperSize
    var svgFilePath: String
    var gcodeCommands: [String]
    var currentCommandIndex: Int
    var pitch: Double
    var zoom: Double
    var origin: CGPoint
    var penSettings: [PenConfiguration]
    var isActive: Bool = false

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
}

 */
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
