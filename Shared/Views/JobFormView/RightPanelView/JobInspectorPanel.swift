//
//  JobInspectorPanel.swift
//  Robart
//
//  Created by Carsten Nichte on 27.04.25.
//

/*
 oben Ebenen, darunter Ebenen-Elemente  darunter:  properties und Robot-Comnands

 Svg properities oben Ebenen, darunter Ebenen-Elemente  darunter:  properties und Robot-Comnands
 */

// JobInspectorPanel.swift - rechter Bereich
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

// MARK: - JobInspectorPanel

struct JobInspectorPanel: View {
    @Binding var currentJob: JobData
    @Binding var selectedMachine: MachineData?

    @State private var selectedTab: InspectorTab = .fileInfo
    @StateObject private var svgInspectorModel: SVGInspectorModel

    enum InspectorTab: String, CaseIterable, Identifiable {
        case fileInfo = "SVG-FileInfo"
        case properties = "SVG-Properties"
        case machine = "Maschine"
        var id: String { rawValue }
    }

    init(currentJob: Binding<JobData>, selectedMachine: Binding<MachineData?>) {
        self._currentJob = currentJob
        self._selectedMachine = selectedMachine
        _svgInspectorModel = StateObject(wrappedValue: SVGInspectorModel(job: currentJob.wrappedValue, machine: selectedMachine.wrappedValue))
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
                        JobInspector_SVGFileInfoView(currentJob: $currentJob)
                    case .properties:
                        JobInspector_SVGPropertiesView(model: svgInspectorModel)
                    case .machine:
                        JobInspector_MachineInfoView(currentJob: $currentJob, selectedMachine: selectedMachine)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.gray.opacity(0.05))
        .onAppear {
            Task {
                await svgInspectorModel.loadAndParseSVG()
            }
        }
    }
}
