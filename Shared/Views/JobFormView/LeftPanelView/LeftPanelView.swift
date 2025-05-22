//
//  LeftPanelView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.05.25.
//
import SwiftUI

struct LeftPanelView: View {
    @Binding var currentJob: JobData
    @Binding var svgFileName: String?
    @Binding var showingFileImporter: Bool
    @Binding var selectedMachine: MachineData?

    var body: some View {
        JobPropertiesPanel(
            currentJob: $currentJob,
            svgFileName: $svgFileName,
            showingFileImporter: $showingFileImporter,
            selectedMachine: $selectedMachine
        )
        .frame(maxWidth: 300)
        .padding(.vertical, 10)
    }
}
