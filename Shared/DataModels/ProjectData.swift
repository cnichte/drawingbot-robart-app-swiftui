//
//  ProjectData.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

// ProjectData.swift
import Foundation

struct ProjectData:  Codable, Identifiable {
    var id: UUID
    var name: String
    var description: String
    var jobs: [PlotJobData] = []
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        jobs: [PlotJobData] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.jobs = jobs
    }
}



