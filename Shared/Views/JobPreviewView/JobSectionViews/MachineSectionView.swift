//
//  MachineSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// MachineSectionView.swift
import SwiftUI

struct MachineSectionView: View {
    @Binding var currentJob: PlotJobData
    @Binding var selectedMachine: MachineData? // Binding für die ausgewählte Maschine
    @EnvironmentObject var assetStores: AssetStores
    
    var body: some View {
        CollapsibleSection(title: "Maschine", systemImage: "gearshape.2", toolbar: { EmptyView() }) {
            VStack(alignment: .leading) {
                Picker("Maschine auswählen", selection: $selectedMachine) {
                    ForEach(assetStores.machineStore.items) { machine in
                        Text(machine.name)
                            .tag(machine as MachineData?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                if let selectedMachine = selectedMachine {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Name: \(selectedMachine.name)")
                        Text("Typ: \(selectedMachine.typ.rawValue)")
                        Text("Größe: \(selectedMachine.size.x) x \(selectedMachine.size.y) mm")
                        Text("Protokoll: \(selectedMachine.protokoll)")
                        Text("Verbindung: \(selectedMachine.connection.connectionID?.uuidString ?? "Keine")")
                        Text("Verbunden: \(selectedMachine.isConnected ? "Ja" : "Nein")")
                    }
                    .padding(.top, 10)
                }

                // Weitere Felder, die mit der Maschine zu tun haben
                HStack {
                    Text("Origin X")
                    TextField("X", value: $currentJob.origin.x, formatter: NumberFormatter())
                }
                HStack {
                    Text("Origin Y")
                    TextField("Y", value: $currentJob.origin.y, formatter: NumberFormatter())
                }
                Toggle("Aktiv", isOn: $currentJob.isActive)
            }
        }
    }
}
