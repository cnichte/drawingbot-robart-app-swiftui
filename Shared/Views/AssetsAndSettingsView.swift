//
//  AssetsAndSettingsView.swift
//  Robart
//
//  Created by Carsten Nichte on 24.04.25.
//

// AssetsAndSettingsView.swift (macOS wieder mit Tabs)
import SwiftUI

struct AssetTab: Identifiable {
    let id = UUID()
    let title: String
    let view: AnyView
}

struct AssetsAndSettingsView: View {
    @EnvironmentObject var connectionsStore: GenericStore<ConnectionData>
    @EnvironmentObject var machineStore: GenericStore<MachineData>
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    @EnvironmentObject var jobStore: GenericStore<PlotJobData>
    @EnvironmentObject var pensStore: GenericStore<PenData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>
    @EnvironmentObject var settingsStore: GenericStore<SettingsData>

    @State private var selectedIndex = 0

    var body: some View {
        #if os(macOS)
        macOSAssetsAndSettingsView
        #else
        iOSAssetsAndSettingsView
        #endif
    }

    // MARK: - iOS Ansicht
    #if os(iOS)
    private var iOSAssetsAndSettingsView: some View {
        NavigationStack {
            List(allTabs) { tab in
                NavigationLink(tab.title) {
                    tab.view
                }
            }
            .navigationTitle("Settings & Assets")
        }
    }
    #endif

    // MARK: - macOS Ansicht
    #if os(macOS)
    private var macOSAssetsAndSettingsView: some View {
        VStack {
            Picker("Kategorie", selection: $selectedIndex) {
                ForEach(Array(allTabs.enumerated()), id: \ .offset) { index, tab in
                    Text(tab.title).tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            allTabs[selectedIndex].view
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    #endif

    private var allTabs: [AssetTab] {
        [
            AssetTab(
                title: "Settings",
                view: AnyView(
                    SettingsView()
                        .environmentObject(settingsStore)
                )
            ),
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
                    PaperManagerView()
                        .environmentObject(paperStore)
                )
            )
        ]
    }
}


// SettingsView.swift bleibt separat, wird im iOSView über NavigationLink eingebunden
