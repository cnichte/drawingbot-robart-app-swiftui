//
//  JobBox.swift
//  Robart
//
//  Created by Carsten Nichte on 23.05.25.
//

// JobBox.swift
import Foundation
import SwiftUI

@MainActor
final class JobBox: ObservableObject {
    @Published var id: UUID
    @Published var name: String
    @Published var description: String
    @Published var svgFilePath: String
    @Published var pitch: Double
    @Published var zoom: Double
    @Published var origin: CGPoint
    @Published var paper: PaperData
    @Published var paperFormatID: UUID?
    @Published var paperOrientation: PaperOrientation
    @Published var penConfiguration: [PenConfiguration]
    @Published var selectedMachine: MachineData
    @Published var signatur: SignatureData?
    @Published var currentCommandIndex: Int
    @Published var isActive: Bool

    init(from job: JobData) {
        self.id = job.id
        self.name = job.name
        self.description = job.description
        self.svgFilePath = job.svgFilePath
        self.pitch = job.pitch
        self.zoom = job.zoom
        self.origin = job.origin
        self.paper = job.paper
        self.paperFormatID = job.paperFormatID
        self.paperOrientation = job.paperOrientation
        self.penConfiguration = job.penConfiguration
        self.selectedMachine = job.selectedMachine
        self.signatur = job.signatur
        self.currentCommandIndex = job.currentCommandIndex
        self.isActive = job.isActive
    }

    func toJobData() -> JobData {
        JobData( // Extra arguments at positions #12, #13, #14, #15 in call
            id: id,
            name: name,
            description: description,
            paper: paper,
            svgFilePath: svgFilePath,
            currentCommandIndex: currentCommandIndex,
            pitch: pitch,
            zoom: zoom,
            origin: origin,
            penConfiguration: penConfiguration,
            selectedMachine: selectedMachine,
            paperFormatID: paperFormatID,
            paperOrientation: paperOrientation,
            signatur: signatur,
            isActive: isActive
        )
    }
}
