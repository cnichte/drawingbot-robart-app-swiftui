//
//  MachineSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// MachineSectionView.swift - Verbesserte Version
import SwiftUI

struct MachineSectionView: View {
    @EnvironmentObject var model: SVGInspectorModel
    @EnvironmentObject var assetStores: AssetStores
    
    var body: some View {
        CollapsibleSection(title: "Maschine", systemImage: "gearshape.2", toolbar: { EmptyView() }) {
            VStack(alignment: .leading) {
                Picker("Maschine auswählen",
                       selection: Binding<UUID?>(
                         get: { model.machine?.id },
                         set: { newID in
                             let sel: MachineData?
                             if let id = newID,
                                let m = assetStores.machineStore.items.first(where: { $0.id == id }) {
                               sel = m
                             } else {
                               sel = .default
                             }
                             model.updateMachine(sel)
                         }
                       )
                ) {
                  Text("– Keine Maschine –").tag(nil as UUID?)
                  ForEach(assetStores.machineStore.items) { machine in
                    Text(machine.name).tag(Optional(machine.id))
                  }
                }
                .pickerStyle(.menu)
                // KEIN onChange mehr nötig!
/*
                Picker("Maschine auswählen", selection: $model.jobBox.machineDataID) {
                    Text("– Keine Maschine –").tag(Optional(MachineData.default.id) as UUID?)
                    ForEach(assetStores.machineStore.items) { machine in
                        Text(machine.name).tag(Optional(machine.id) as UUID?)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: model.jobBox.machineDataID) { _, newID in
                    appLog(.info, "Picker changed to machineID: \(newID?.uuidString ?? "nil")")
                    
                    let selectedMachine: MachineData?
                    if let id = newID {
                        if id == MachineData.default.id {
                            selectedMachine = .default
                        } else {
                            selectedMachine = assetStores.machineStore.items.first(where: { $0.id == id }) ?? .default
                        }
                    } else {
                        selectedMachine = .default
                    }
                    
                    // Verwende die zentrale updateMachine Methode
                    model.updateMachine(selectedMachine)
                }
*/
                // Zeige die Details nur, wenn eine Maschine ausgewählt wurde
                if let machine = model.machine, machine.id != MachineData.default.id {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Name: \(machine.name)")
                        Text("Typ: \(machine.typ.rawValue)")
                        Text("Größe: \(machine.size.x) x \(machine.size.y) mm")
                        Text("Protokoll: \(machine.commandProtocol)")
                        Text("Verbindung: \(machine.connection.connectionID?.uuidString ?? "Keine")")
                        Text("Verbunden: \(machine.isConnected ? "Ja" : "Nein")")
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
                    model.syncJobBoxBack()
                }
                
                HStack {
                    Text("Origin Y")
                    TextField("Y", value: $model.jobBox.origin.y, formatter: NumberFormatter())
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                }
                .onChange(of: model.jobBox.origin.y) {
                    model.syncJobBoxBack()
                }
            }
        }
    }
}
