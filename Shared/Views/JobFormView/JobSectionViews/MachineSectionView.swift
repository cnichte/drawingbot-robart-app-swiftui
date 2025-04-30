//
//  MachineSectionView.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// MachineSectionView.swift
import SwiftUI

struct MachineSectionView: View {
    @Binding var currentJob: JobData
    @Binding var selectedMachine: MachineData?
    @EnvironmentObject var assetStores: AssetStores

    var body: some View {
        CollapsibleSection(title: "Maschine", systemImage: "gearshape.2", toolbar: { EmptyView() }) {
            VStack(alignment: .leading) {
                Picker("Maschine auswählen", selection: $currentJob.selectedMachine) {
                    Text("– Keine Maschine –").tag(MachineData.default)
                    ForEach(assetStores.machineStore.items) { machine in
                        Text(machine.name)
                            .tag(machine)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                if !currentJob.selectedMachine.isDefault {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Name: \(currentJob.selectedMachine.name)")
                        Text("Typ: \(currentJob.selectedMachine.typ.rawValue)")
                        Text("Größe: \(currentJob.selectedMachine.size.x) x \(currentJob.selectedMachine.size.y) mm")
                        Text("Protokoll: \(currentJob.selectedMachine.commandProtocol)")
                        Text("Verbindung: \(currentJob.selectedMachine.connection.connectionID?.uuidString ?? "Keine")")
                        Text("Verbunden: \(currentJob.selectedMachine.isConnected ? "Ja" : "Nein")")
                    }
                    .padding(.top, 10)
                }

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
        .onChange(of: currentJob.selectedMachine) { oldValue, newValue in //TODO: Fix für die Meldung unten...
            selectedMachine = newValue.isDefault ? nil : newValue
        }
        .onChange(of: selectedMachine) { oldValue, newValue  in
            currentJob.selectedMachine = newValue ?? .default
        }
        .onAppear {
            // Initialzustand synchronisieren
            selectedMachine = currentJob.selectedMachine.isDefault ? nil : currentJob.selectedMachine
        }
    }
}
