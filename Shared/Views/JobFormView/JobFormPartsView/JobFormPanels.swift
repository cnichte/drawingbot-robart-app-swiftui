//
//  JobFormPanels.swift
//  Robart
//
//  Created by Carsten Nichte on 03.05.25.
//

import SwiftUI

// JobFormPanels.swift
struct SidebarPanelView: View {
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

struct CenterPanelView: View {
    @Binding var zoom: Double
    @Binding var pitch: Double
    @Binding var origin: CGPoint
    @Binding var job: JobData
    @Binding var previewMode: JobFormView.PreviewMode
    @Binding var isSidebarVisible: Bool
    @Binding var isInspectorVisible: Bool

    var body: some View {
        PaperPanel(zoom: $zoom, pitch: $pitch, origin: $origin, job: $job)
            .background(ColorHelper.backgroundColor)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Picker("Vorschau", selection: $previewMode) {
                        ForEach(JobFormView.PreviewMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
                ToolbarItem(placement: .automatic) {
                    CustomToolbarButton(title: "", icon: "sidebar.left", style: .secondary, role: nil,hasBorder:false, iconSize: .large ) {
                        isSidebarVisible.toggle()
                    }
                }
                ToolbarItem(placement: .automatic) {
                    CustomToolbarButton(title: "", icon: "sidebar.left", style: .secondary, role: nil,hasBorder:false, iconSize: .large ) {
                        isInspectorVisible.toggle()
                    }
                }
            }
    }
}

struct InspectorPanelView: View {
    @Binding var currentJob: JobData
    @Binding var selectedMachine: MachineData?

    var body: some View {
        JobInspectorPanel(
            currentJob: $currentJob,
            selectedMachine: $selectedMachine
        )
    }
}
