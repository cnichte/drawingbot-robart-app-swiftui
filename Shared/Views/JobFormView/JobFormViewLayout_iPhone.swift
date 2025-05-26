//
//  JobPreviewLayout_iPhone.swift
//  Robart
//
//  Created by Carsten Nichte on 03.05.25.
//

// JobPreviewLayout_iPhone.swift
#if os(iOS)
import SwiftUI

struct iPhoneJobPreviewLayout: View {
    @Binding var currentJob: JobData
    @Binding var svgFileName: String?
    @Binding var showingFileImporter: Bool
    @Binding var selectedMachine: MachineData?
    @Binding var zoom: Double
    @Binding var pitch: Double
    @Binding var origin: CGPoint
    @Binding var previewMode: JobFormView.PreviewMode
    @Binding var showingSettings: Bool
    @Binding var showingInspector: Bool

    @EnvironmentObject var plotJobStore: GenericStore<JobData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    @EnvironmentObject var paperFormatsStore: GenericStore<PaperFormatData>

    var body: some View {
        VStack {
            CenterPanelView(
                previewMode: $previewMode,
                isSidebarVisible: .constant(false),
                isInspectorVisible: .constant(false)
            )
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Einstellungen") { showingSettings.toggle() }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Inspector") { showingInspector.toggle() }
            }
        }
        .sheet(isPresented: $showingSettings) {
            LeftPanelView(
                svgFileName: $svgFileName,
                showingFileImporter: $showingFileImporter,
            )
        }
        .sheet(isPresented: $showingInspector) {
            RightPanelView()
        }
    }
}
#endif
