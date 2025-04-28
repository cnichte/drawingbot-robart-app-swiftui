//
//  ConnectionManagerView.swift
//  Robart
//
//  Created by Carsten Nichte on 23.04.25.
//

// ConnectionManagerView.swift
import SwiftUI
struct ConnectionManagerView: View {
    var body: some View {
        ItemManagerView<ConnectionData, ConnectionFormView>(
            title: "Connection",
            createItem: { ConnectionData(name: "Neue Connection") },
            buildForm: { binding in
                ConnectionFormView(data: binding)
            }
        )
    }
}
