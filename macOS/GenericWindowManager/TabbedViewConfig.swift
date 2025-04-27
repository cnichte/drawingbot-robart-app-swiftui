//
//  TabbedViewConfig.swift
//  Robart
//
//  Created by Carsten Nichte on 21.04.25.
//

// TabbedViewConfig.swift
#if os(macOS)
import SwiftUI

struct TabbedViewConfig {
    let title: String
    let view: AnyView
    let environmentObjects: [AnyViewModifier]

    init<V: View>(
        title: String,
        view: V,
        environmentObjects: [AnyViewModifier] = []
    ) {
        var modifiedView: AnyView = AnyView(view)
        for modifier in environmentObjects {
            modifiedView = AnyView(modifier.apply(to: modifiedView))
        }
        self.title = title
        self.view = modifiedView
        self.environmentObjects = environmentObjects
    }
}
#endif


/* Beispiel Anwendung:
            Button("Assets") {
                
                WindowManager.shared.openTabbedWindow(
                    id: .assetManager,
                    title: "Asset-Manager",
                    tabs: [
                        TabbedViewConfig( // TODO: Generic View überall benutzen!
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
                        TabbedViewConfig( // TODO: Generic View überall benutzen!
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
                        TabbedViewConfig( // TODO: Generic View überall benutzen!
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
                        TabbedViewConfig( // TODO: Generic View überall benutzen!
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
                        TabbedViewConfig( // TODO: Generic View überall benutzen!
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
                        ),
                        
                    ]
                )
            }
            .buttonStyle(.borderedProminent)
*/
