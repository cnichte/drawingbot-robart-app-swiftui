//
//  JobPreviewLayout_Mac.swift
//  Robart
//
//  Created by Carsten Nichte on 03.05.25.
//

// JobPreviewLayout_Mac.swift
#if os(macOS)
import SwiftUI

struct MacJobPreviewLayoutView: View {
    @EnvironmentObject var model: SVGInspectorModel // TODO: NEW
    
    // @Binding var currentJob: JobData
    @Binding var svgFileName: String?
    @Binding var showingFileImporter: Bool
    // @Binding var selectedMachine: MachineData?

    @Binding var zoom: Double
    @Binding var pitch: Double
    @Binding var origin: CGPoint
    @Binding var previewMode: JobFormView.PreviewMode

    @Binding var isSidebarVisible: Bool
    @Binding var isInspectorVisible: Bool
    @Binding var inspectorWidth: CGFloat

    @EnvironmentObject var plotJobStore: GenericStore<JobData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormatData>

    var body: some View {
        CustomSplitView(
            isLeftVisible: $isSidebarVisible,
            isRightVisible: $isInspectorVisible,
            rightPanelWidth: $inspectorWidth,
            leftView: {
                LeftPanelView(
                    // currentJob: $currentJob,
                    svgFileName: $svgFileName,
                    showingFileImporter: $showingFileImporter,
                    // selectedMachine: $selectedMachine
                    
                )
                .environmentObject(plotJobStore)
                .environmentObject(paperStore)
                .environmentObject(paperFormatsStore)
            },
            centerView: {
                CenterPanelView(
                    zoom: $zoom,
                    pitch: $pitch,
                    origin: $origin,
                    // job: $currentJob,
                    previewMode: $previewMode,
                    
                    isSidebarVisible: $isSidebarVisible,
                    isInspectorVisible: $isInspectorVisible
                )
            },
            rightView: {
                RightPanelView(
                    /*
                    currentJob: $currentJob,
                    selectedMachine: $selectedMachine
                     */
                )
            }
        )
    }
}
#endif
