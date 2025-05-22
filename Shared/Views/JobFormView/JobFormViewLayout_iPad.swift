//
//  JobPreviewLayout_iPad.swift
//  Robart
//
//  Created by Carsten Nichte on 03.05.25.
//

#if os(iOS)
import SwiftUI

struct iPadJobPreviewLayout: View {
    @Binding var currentJob: JobData
    @Binding var svgFileName: String?
    @Binding var showingFileImporter: Bool
    @Binding var selectedMachine: MachineData?
    @Binding var zoom: Double
    @Binding var pitch: Double
    @Binding var origin: CGPoint
    @Binding var previewMode: JobFormView.PreviewMode
    @Binding var isSidebarVisible: Bool
    @Binding var showingInspector: Bool

    @EnvironmentObject var plotJobStore: GenericStore<JobData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormatData>

    var body: some View {
        HStack {
            if isSidebarVisible {
                LeftPanelView(
                    currentJob: $currentJob,
                    svgFileName: $svgFileName,
                    showingFileImporter: $showingFileImporter,
                    selectedMachine: $selectedMachine
                )
            }
            CenterPanelView(
                zoom: $zoom,
                pitch: $pitch,
                origin: $origin,
                job: $currentJob,
                previewMode: $previewMode,
                isSidebarVisible: $isSidebarVisible,
                isInspectorVisible: $showingInspector
            )
        }
        .toolbar {
            /*
            CustomToolbarButton(title: "", icon: "sidebar.right", style: .secondary, role: nil ,hasBorder:false, iconSize: .large ) {
                showingInspector.toggle()
            }
            */
            /*
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Einstellungen") { showingInspector = false } // Links: Einstellungen
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Inspector") { showingInspector = true } // Rechts: Inspector
            }
            */
        }
        .sheet(isPresented: $showingInspector) {
            RightPanelView(
                currentJob: $currentJob,
                selectedMachine: $selectedMachine
            )
        }
    }
}
#endif
