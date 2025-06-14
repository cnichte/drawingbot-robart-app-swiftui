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
    @EnvironmentObject var assetStores: AssetStores

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
            Picker("", selection: $selectedIndex) {
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
                title: "Allgemein",
                view: AnyView(
                    SettingsView()
                        .environmentObject(assetStores)
                )
            ),
            AssetTab(
                title: "Verbindungen",
                view: AnyView(
                    ItemManagerView<ConnectionData, ConnectionFormView>(
                        title: "Verbindungen",
                        createItem: { ConnectionData(name: "Neue Verbindung") },
                        buildForm: { ConnectionFormView(data: $0) }
                    )
                    .environmentObject(assetStores)
                )
            ),
            AssetTab(
                title: "Maschinen",
                view: AnyView(
                    ItemManagerView<MachineData, MachineFormView>(
                        title: "Maschinen",
                        createItem: { MachineData(name: "Neue Maschine") },
                        buildForm: { MachineFormView(data: $0) }
                    )
                    .environmentObject(assetStores)
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
                    .environmentObject(assetStores)
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
                    .environmentObject(assetStores)
                )
            ),
            AssetTab(
                title: "Papiere",
                view: AnyView(
                    PaperManagerView()
                        .environmentObject(assetStores)
                )
            )
        ]
    }
}


// SettingsView.swift bleibt separat, wird im iOSView über NavigationLink eingebunden
