//
//  ProjectData.swift
//  RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

// ProjectData.swift
import Foundation

struct ProjectData: Codable, Identifiable, Hashable, ManageableItem, Defaultable {
    var id: UUID
    var name: String
    var description: String
    var jobs: [JobData] = []

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        jobs: [JobData] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.jobs = jobs
    }
    
    static var `default`: ProjectData {
        ProjectData(id: UUID.force("48e24211-545f-4c4e-8f1e-7466da3a11b5"), name: "Kein Projekt")
    }
    
    static func == (lhs: ProjectData, rhs: ProjectData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}




