//
//  CenterPanelView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.05.25.
//

// CenterPanelView.swift
import SwiftUI

struct CenterPanelView: View {
    @Binding var zoom: Double
    @Binding var pitch: Double
    @Binding var origin: CGPoint
    // @Binding var job: JobData
    @Binding var previewMode: JobFormView.PreviewMode
    @Binding var isSidebarVisible: Bool
    @Binding var isInspectorVisible: Bool

    var body: some View {
        PaperPanel(zoom: $zoom, pitch: $pitch, origin: $origin)
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
