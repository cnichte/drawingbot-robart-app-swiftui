//
//  JobInspector_MachineInfoView.swift
//  Robart
//
//  Created by Carsten Nichte on 01.05.25.
//

// JobInspector_MachineInfoView.swift
import SwiftUI

struct JobInspector_MachineInfoView: View {
    @EnvironmentObject var model: SVGInspectorModel

    // TODO: Ich kann auf selectedMachine auch durch currentJob zugreifen: currentJob.selectedMachine - was ist sinnvoller, was funktioniert, was nicht?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let machine = model.machine {
                
                Text("Maschinenname: \(machine.name)")
                    .font(.headline)
                Text("Typ: \(machine.typ.rawValue)")
                Text("Protokoll: \(machine.commandProtocol)")
                Text("Größe: \(machine.size.x) x \(machine.size.y) mm")
                Text("Verbunden: \(machine.isConnected ? "Ja" : "Nein")")

                Divider()

                Text("commands:")
                ForEach(machine.commandItems, id: \.id) { template in
                    VStack(alignment: .leading) {
                        Text("Befehl: \(template.command)")
                        Text("Beschreibung: \(template.description)")
                    }
                    .padding(.bottom, 4)
                }

                Divider()

                Text("Optionen:")
                ForEach(machine.options, id: \.id) { option in
                    VStack(alignment: .leading) {
                        Text("Option: \(option.option)")
                        Text("Wert: \(option.valueAsString)")
                    }
                    .padding(.bottom, 4)
                }
            } else {
                Text("Keine Maschine ausgewählt.")
            }
        }
    }
}
