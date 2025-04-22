//
//  PenManagerView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

import SwiftUI
#if os(macOS)
struct PenManagerView: View {
    var body: some View {
        ItemManagerView<PenData, PenFormView>(
            title: "Stifte",
            createItem: { PenData(name: "Neuer Stift") },
            buildForm: { binding in
                PenFormView(data: binding)
            }
        )
    }
}
#endif
