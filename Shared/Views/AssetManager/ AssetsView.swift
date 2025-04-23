//
//   AssetsView.swift
//  Robart
//
//  Created by Carsten Nichte on 23.04.25.
//

// AssetsView.swift
// AssetsView.swift (plattformübergreifend)
import SwiftUI

struct AssetsView: View {
    @EnvironmentObject var connectionsStore: GenericStore<ConnectionData>
    @EnvironmentObject var machineStore: GenericStore<MachineData>
    @EnvironmentObject var projectStore: GenericStore<ProjectData>
    @EnvironmentObject var jobStore: GenericStore<PlotJobData>
    @EnvironmentObject var pensStore: GenericStore<PenData>
    @EnvironmentObject var paperStore: GenericStore<PaperData>

    var body: some View {
        #if os(macOS)
        macOSAssetsView
        #else
        iOSAssetsView
        #endif
    }

    // MARK: - macOS: Tabs
#if os(macOS)
    private var macOSAssetsView: some View {
        Button("Asset-Manager öffnen") {
            WindowManager.shared.openTabbedWindow(
                id: .assetManager,
                title: "Asset-Manager",
                tabs: [
                    TabbedViewConfig(
                        title: "Connection",
                        view: ItemManagerView<ConnectionData, ConnectionFormView>(
                            title: "Connection",
                            createItem: { ConnectionData(name: "Neue Connection") },
                            buildForm: { binding in
                                ConnectionFormView(data: binding)
                            }
                        ),
                        environmentObjects: [
                            EnvironmentObjectModifier(object: connectionsStore)
                        ]
                    ),
                    TabbedViewConfig(
                        title: "Maschine",
                        view: ItemManagerView<MachineData, MachineFormView>(
                            title: "Maschine",
                            createItem: { MachineData(name: "Neue Maschine") },
                            buildForm: { binding in
                                MachineFormView(data: binding)
                            }
                        ),
                        environmentObjects: [
                            EnvironmentObjectModifier(object: machineStore)
                        ]
                    ),
                    TabbedViewConfig(
                        title: "Projekte",
                        view: ItemManagerView<ProjectData, ProjectFormView>(
                            title: "Projekte",
                            createItem: { ProjectData(name: "Neues Projekt") },
                            buildForm: { binding in
                                ProjectFormView(data: binding)
                            }
                        ),
                        environmentObjects: [
                            EnvironmentObjectModifier(object: projectStore),
                            EnvironmentObjectModifier(object: jobStore)
                        ]
                    ),
                    TabbedViewConfig(
                        title: "Stifte",
                        view: ItemManagerView<PenData, PenFormView>(
                            title: "Stifte",
                            createItem: { PenData(name: "Neuer Stift") },
                            buildForm: { binding in
                                PenFormView(data: binding)
                            }
                        ),
                        environmentObjects: [
                            EnvironmentObjectModifier(object: pensStore)
                        ]
                    ),
                    TabbedViewConfig(
                        title: "Papier",
                        view: ItemManagerView<PaperData, PaperFormView>(
                            title: "Papier",
                            createItem: { PaperData(name: "Neues Papier") },
                            buildForm: { binding in
                                PaperFormView(data: binding)
                            }
                        ),
                        environmentObjects: [
                            EnvironmentObjectModifier(object: paperStore)
                        ]
                    )
                ]
            )
        }
        .padding()
    }
#endif
    // MARK: - iOS: Navigation
#if os(iOS)
    private var iOSAssetsView: some View {
        NavigationStack {
            List {
                NavigationLink("Connection") {
                    ItemManagerView<ConnectionData, ConnectionFormView>(
                        title: "Connection",
                        createItem: { ConnectionData(name: "Neue Connection") },
                        buildForm: { binding in
                            ConnectionFormView(data: binding)
                        }
                    )
                    .environmentObject(connectionsStore)
                }

                NavigationLink("Maschine") {
                    ItemManagerView<MachineData, MachineFormView>(
                        title: "Maschine",
                        createItem: { MachineData(name: "Neue Maschine") },
                        buildForm: { binding in
                            MachineFormView(data: binding)
                        }
                    )
                    .environmentObject(machineStore)
                }

                NavigationLink("Projekte") {
                    ItemManagerView<ProjectData, ProjectFormView>(
                        title: "Projekte",
                        createItem: { ProjectData(name: "Neues Projekt") },
                        buildForm: { binding in
                            ProjectFormView(data: binding)
                        }
                    )
                    .environmentObject(projectStore)
                    .environmentObject(jobStore)
                }

                NavigationLink("Stifte") {
                    ItemManagerView<PenData, PenFormView>(
                        title: "Stifte",
                        createItem: { PenData(name: "Neuer Stift") },
                        buildForm: { binding in
                            PenFormView(data: binding)
                        }
                    )
                    .environmentObject(pensStore)
                }

                NavigationLink("Papier") {
                    ItemManagerView<PaperData, PaperFormView>(
                        title: "Papier",
                        createItem: { PaperData(name: "Neues Papier") },
                        buildForm: { binding in
                            PaperFormView(data: binding)
                        }
                    )
                    .environmentObject(paperStore)
                }
            }
            .navigationTitle("Assets")
        }
    }
#endif
}
