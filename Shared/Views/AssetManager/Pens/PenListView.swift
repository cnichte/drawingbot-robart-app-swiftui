//
//  PenListView.swift
//  Robart
//
//  Created by Carsten Nichte on 20.04.25.
//

// MARK: - PenListView.swift
import SwiftUI

struct PenListView: View {
    let pens: [PenData]
    @Binding var selectedPenID: UUID?
    var onDelete: (PenData) -> Void
    var onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Stifte")
                    .font(.title2.bold())
                Spacer()
                Button(action: onAdd) {
                    Label("Stift hinzufügen", systemImage: "plus")
                }
            }
            .padding([.horizontal, .top])

            List(selection: $selectedPenID) {
                ForEach(pens) { pen in
                    HStack {
                        Text(pen.name).bold()
                        Spacer()
                        Button(role: .destructive) {
                            onDelete(pen)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .tag(pen.id)
                }
            }
        }
        .frame(minWidth: 280, maxWidth: 320)
        .background(ColorHelper.backgroundColor)
        .padding(.trailing, 8)
    }
}
