//
//  PaperManagerView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

import SwiftUI
#if os(macOS)
struct PaperManagerView: View {
    var body: some View {
        ItemManagerView<PaperData, PaperFormView>(
            title: "Papier",
            createItem: { PaperData(name: "Neues Papier") },
            buildForm: { binding in
                PaperFormView(data: binding)
            }
        )
    }
}
#endif
