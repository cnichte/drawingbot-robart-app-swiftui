//
//  MachineSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// MachineSectionView.swift
import SwiftUI

struct MachineSectionView: View {
    @EnvironmentObject var model: SVGInspectorModel
    @EnvironmentObject var assetStores: AssetStores
    
    var body: some View {
        CollapsibleSection(title: "Maschine", systemImage: "gearshape.2", toolbar: { EmptyView() }) {
            VStack(alignment: .leading) {
                Picker("Maschine auswählen", selection: $model.jobBox.machineDataID) {
                    Text("– Keine Maschine –").tag(Optional(MachineData.default.id) as UUID?)
                    ForEach(assetStores.machineStore.items) { machine in
                        Text(machine.name).tag(Optional(machine.id) as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: model.jobBox.machineDataID) { _, newID in
                    appLog(.info, "Picker changed to machineID: \(newID?.uuidString ?? "nil")")
                    if let id = newID {
                        if id == MachineData.default.id {
                            model.jobBox.machineData = .default
                            model.machine = .default
                        } else if let selectedMachine = assetStores.machineStore.items.first(where: { $0.id == id }) {
                            model.jobBox.machineData = selectedMachine
                            model.machine = selectedMachine
                        }
                    } else {
                        model.jobBox.machineData = .default
                        model.machine = .default
                    }
                    model.syncJobBoxBack() // Synchronisiere Änderungen zurück in job
                    // Neu: Parse SVG mit der neuen Maschine
                    Task {
                        appLog(.info, "Loading and parsing SVG for new machine: \(model.machine?.name ?? "default")")
                        await model.loadAndParseSVG()
                    }
                }
                
                // Zeige die Details nur, wenn eine Maschine ausgewählt wurde
                if model.jobBox.machineDataID != MachineData.default.id {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Name: \(model.jobBox.machineData.name)")
                        Text("Typ: \(model.jobBox.machineData.typ.rawValue)")
                        Text("Größe: \(model.jobBox.machineData.size.x) x \(model.jobBox.machineData.size.y) mm")
                        Text("Protokoll: \(model.jobBox.machineData.commandProtocol)")
                        Text("Verbindung: \(model.jobBox.machineData.connection.connectionID?.uuidString ?? "Keine")")
                        Text("Verbunden: \(model.jobBox.machineData.isConnected ? "Ja" : "Nein")")
                    }
                    .padding(.top, 10)
                }
                
                HStack {
                    Text("Origin X")
                    TextField("X", value: $model.jobBox.origin.x, formatter: NumberFormatter())
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }
                .onChange(of: model.jobBox.origin.x) {
                    // model.syncJobBoxBack()
                    // Task {  await model.save(using: assetStores.plotJobStore) }
                }
                
                HStack {
                    Text("Origin Y")
                    TextField("Y", value: $model.jobBox.origin.y, formatter: NumberFormatter())
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }
                .onChange(of: model.jobBox.origin.y) {
                    // model.syncJobBoxBack()
                    // Task {  await model.save(using: assetStores.plotJobStore) }
                }
            }
        }
    }
}
