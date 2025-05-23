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
                Picker("Maschine auswählen", selection: Binding<MachineData?> (
                    get: { model.machine },
                    set: { newValue in
                        model.machine = newValue
                        model.job.selectedMachine = newValue ?? .default
                        Task {
                            await model.loadAndParseSVG()
                            await model.save(using: assetStores.plotJobStore)
                        }
                    }
                )) {
                    Text("– Keine Maschine –").tag(Optional(MachineData.default))
                    ForEach(assetStores.machineStore.items) { machine in
                        Text(machine.name).tag(Optional(machine))
                    }
                }
                .pickerStyle(MenuPickerStyle())

                if let machine = model.machine, !machine.isDefault {
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
                    TextField("X", value: Binding(
                        get: { model.job.origin.x },
                        set: { model.job.origin.x = $0 }
                    ), formatter: NumberFormatter())
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("Origin Y")
                    TextField("Y", value: Binding(
                        get: { model.job.origin.y },
                        set: { model.job.origin.y = $0 }
                    ), formatter: NumberFormatter())
                    .frame(width: 80)
                    .textFieldStyle(.roundedBorder)
                }
            }
        }
        .onChange(of: model.job) {
            Task {
                do {
                    try await model.save(using: assetStores.plotJobStore)
                } catch {
                    appLog(.error, "Fehler beim Speichern: \(error)")
                }
            }
        }
    }
}
