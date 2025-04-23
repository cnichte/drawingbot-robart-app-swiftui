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
    
    @State private var selectedTab = 0
    
    var body: some View {
#if os(macOS)
        macOSAssetsView
#else
        iOSAssetsView
#endif
    }
    
    // MARK: - macOS: Tabs
    // TabView durch andere UI-Komponenten ersetzen (zB Picker + ZStack oder SegmentedControl mit VStack), in meinem Fall reicht es, einfach keine tabViewStyle zu setzen. Für macOS wäre eine Sidebar-Navigation (wie in System Settings) möglich - oder den bestehenen Tab-Zugriff via Picker behalten?
#if os(macOS)
    private var macOSAssetsView: some View {
        VStack {
                   Picker("Kategorie", selection: $selectedTab) {
                       Text("Connection").tag(0)
                       Text("Maschine").tag(1)
                       Text("Projekte").tag(2)
                       Text("Stifte").tag(3)
                       Text("Papier").tag(4)
                   }
                   .pickerStyle(SegmentedPickerStyle())
                   .padding()

                   TabView(selection: $selectedTab) {
                       TabManagerView<ConnectionData, ConnectionFormView>(
                           title: "Connection",
                           formBuilder: { binding in
                               ConnectionFormView(data: binding)
                           }
                       )
                       .tag(0)
                       .environmentObject(connectionsStore)

                       TabManagerView<MachineData, MachineFormView>(
                           title: "Maschine",
                           formBuilder: { binding in
                               MachineFormView(data: binding)
                           }
                       )
                       .tag(1)
                       .environmentObject(machineStore)

                       TabManagerView<ProjectData, ProjectFormView>(
                           title: "Projekte",
                           formBuilder: { binding in
                               ProjectFormView(data: binding) // Dummy für macOS
                           }
                       )
                       .tag(2)
                       .environmentObject(projectStore)
                       .environmentObject(jobStore)

                       TabManagerView<PenData, PenFormView>(
                           title: "Stifte",
                           formBuilder: { binding in
                               PenFormView(data: binding)
                           }
                       )
                       .tag(3)
                       .environmentObject(pensStore)

                       TabManagerView<PaperData, PaperFormView>(
                           title: "Papier",
                           formBuilder: { binding in
                               PaperFormView(data: binding)
                           }
                       )
                       .tag(4)
                       .environmentObject(paperStore)
                   }
                   // .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
               }
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
