//
//  InspectorPanelView.swift
//  Robart
//
//  Created by Carsten Nichte on 03.05.25.
//

// InspectorPanelView.swift
import SwiftUI

struct RightPanelView: View {
    @Binding var currentJob: JobData
    @Binding var selectedMachine: MachineData?

    var body: some View {
        JobInspectorPanel(
            currentJob: $currentJob,
            selectedMachine: $selectedMachine
        )
    }
}
