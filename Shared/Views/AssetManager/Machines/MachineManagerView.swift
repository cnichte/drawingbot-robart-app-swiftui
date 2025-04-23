//
//  MachineManagerView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

// MachineManagerView.swift
import SwiftUI
struct MachineManagerView: View {
    var body: some View {
        ItemManagerView<MachineData, MachineFormView>(
            title: "Maschine",
            createItem: { MachineData(name: "Neue Maschine") },
            buildForm: { binding in
                MachineFormView(data: binding)
            }
        )
    }
}
