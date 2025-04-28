//
//  ProjectManagerView.swift
//  Robart
//
//  Created by Carsten Nichte on 16.04.25.
//

// ProjectManagerView.swift
import SwiftUI

struct ProjectManagerView: View {
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    @EnvironmentObject var jobStore: GenericStore<PlotJobData>

    var body: some View {
        ItemManagerView<ProjectData, ProjectFormView>(
            title: "Projekte",
            createItem: { ProjectData(name: "Neues Projekt") },
            buildForm: { binding in
                ProjectFormView(data: binding)
            }
        )
    }
}
