//
//  JobBox.swift
//  Robart
//
//  Created by Carsten Nichte on 23.05.25.
//

// JobBox.swift
import Foundation
import SwiftUI

// Das ist ein Wrapper um JobData, der die einzelnen Properties Observable macht?
@MainActor
final class JobBox: ObservableObject {
    @Published var id: UUID
    @Published var name: String
    @Published var description: String
    @Published var svgFilePath: String
    @Published var angle: Double
    @Published var zoom: Double
    @Published var origin: CGPoint
    @Published var paperData: PaperData
    @Published var paperDataID: UUID? // Für Picker
    @Published var paperOrientation: PaperOrientation
    @Published var penConfiguration: [PenConfiguration]
    @Published var penConfigurationIDs: [UUID?]
    @Published var machineData: MachineData
    @Published var machineDataID: UUID? // Für Picker
    @Published var signatur: SignatureData?
    @Published var currentCommandIndex: Int
    @Published var isActive: Bool

    init(from job: JobData) {
        self.id = job.id
        self.name = job.name
        self.description = job.description
        self.svgFilePath = job.svgFilePath
        self.angle = job.angle
        self.zoom = job.zoom
        self.origin = job.origin
        self.paperData = job.paperData
        self.paperDataID = job.paperDataID
        self.paperOrientation = job.paperOrientation
        self.penConfiguration = job.penConfiguration
        self.penConfigurationIDs = job.penConfigurationIDs
        self.machineData = job.machineData
        self.machineDataID = job.machineDataID // NEU
        self.signatur = job.signaturData
        self.currentCommandIndex = job.currentCommandIndex
        self.isActive = job.isActive
    }

    func toJobData() -> JobData {
        JobData(
            id: id,
            name: name,
            description: description,
            svgFilePath: svgFilePath,
            currentCommandIndex: currentCommandIndex,
            angle: angle,
            zoom: zoom,
            origin: origin,
            penConfiguration: penConfiguration,
            penConfigurationIDs: penConfigurationIDs,
            machineData: machineData,
            machineDataID: machineDataID,
            paperData: paperData,
            paperDataID: paperDataID,
            paperOrientation: paperOrientation,
            signatur: signatur,
            isActive: isActive
        )
    }
}
