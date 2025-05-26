//
//  RightPanelView.swift
//  Robart
//
//  Created by Carsten Nichte on 03.05.25.
//

// RightPanelView.swift
import SwiftUI

// MARK: - Hilfs-Modelle

struct SVGLayer: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

struct SVGProperty: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}

// MARK: - RightPanelView

struct RightPanelView: View {
    @State private var selectedTab: InspectorTab = .fileInfo

    enum InspectorTab: String, CaseIterable, Identifiable {
        case fileInfo = "SVG-FileInfo"
        case properties = "SVG-Properties"
        case machine = "Maschine"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Picker("", selection: $selectedTab) {
                ForEach(InspectorTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Divider()
                .padding(.horizontal, 8)
                .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .fileInfo:
                        JobInspector_SVGFileInfoView()
                    case .properties:
                        JobInspector_SVGPropertiesView()
                    case .machine:
                        JobInspector_MachineInfoView()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.gray.opacity(0.05))
    }
}
