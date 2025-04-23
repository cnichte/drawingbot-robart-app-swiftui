//
//   AssetsView.swift
//  Robart
//
//  Created by Carsten Nichte on 23.04.25.
//

// AssetsView.swift (plattformübergreifend)
import SwiftUI

struct AssetTab: Identifiable {
    let id = UUID()
    let title: String
    let view: AnyView
}

struct AssetsView: View {
    @EnvironmentObject var connectionsStore: GenericStore<ConnectionData>
    @EnvironmentObject var machineStore: GenericStore<MachineData>
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    @EnvironmentObject var jobStore: GenericStore<PlotJobData>
    @EnvironmentObject var pensStore: GenericStore<PenData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>

    @State private var selectedIndex = 0

    var body: some View {
        #if os(macOS)
        macOSAssetsView
        #else
        iOSAssetsView
        #endif
    }

    // MARK: - iOS Ansicht
    #if os(iOS)
    private var iOSAssetsView: some View {
        NavigationStack {
            List(allAssetTabs) { tab in
                NavigationLink(tab.title) {
                    tab.view
                }
            }
            .navigationTitle("Assets")
        }
    }
    #endif

    // MARK: - macOS Ansicht
    #if os(macOS)
    private var macOSAssetsView: some View {
        VStack {
            Picker("Kategorie", selection: $selectedIndex) {
                ForEach(Array(allAssetTabs.enumerated()), id: \.offset) { index, tab in
                    Text(tab.title).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            allAssetTabs[selectedIndex].view
        }
    }
    #endif
    
    private var allAssetTabs: [AssetTab] {
        [
            AssetTab(
                title: "Connection",
                view: AnyView(
                    ItemManagerView<ConnectionData, ConnectionFormView>(
                        title: "Connection",
                        createItem: { ConnectionData(name: "Neue Connection") },
                        buildForm: { ConnectionFormView(data: $0) }
                    )
                    .environmentObject(connectionsStore)
                )
            ),
            AssetTab(
                title: "Maschine",
                view: AnyView(
                    ItemManagerView<MachineData, MachineFormView>(
                        title: "Maschine",
                        createItem: { MachineData(name: "Neue Maschine") },
                        buildForm: { MachineFormView(data: $0) }
                    )
                    .environmentObject(machineStore)
                )
            ),
            AssetTab(
                title: "Projekte",
                view: AnyView(
                    ItemManagerView<ProjectData, ProjectFormView>(
                        title: "Projekte",
                        createItem: { ProjectData(name: "Neues Projekt") },
                        buildForm: { ProjectFormView(data: $0) }
                    )
                    .environmentObject(projectStore)
                    .environmentObject(jobStore)
                )
            ),
            AssetTab(
                title: "Stifte",
                view: AnyView(
                    ItemManagerView<PenData, PenFormView>(
                        title: "Stifte",
                        createItem: { PenData(name: "Neuer Stift") },
                        buildForm: { PenFormView(data: $0) }
                    )
                    .environmentObject(pensStore)
                )
            ),
            AssetTab(
                title: "Papier",
                view: AnyView(
                    ItemManagerView<PaperData, PaperFormView>(
                        title: "Papier",
                        createItem: { PaperData(name: "Neues Papier") },
                        buildForm: { PaperFormView(data: $0) }
                    )
                    .environmentObject(paperStore)
                )
            )
        ]
    }
}
