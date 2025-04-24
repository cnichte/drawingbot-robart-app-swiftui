//
//  AssetListView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

// AssetListView.swift
#if os(macOS)
import SwiftUI

// deprecated
struct ItemListView<Item: ManageableItem>: View {
    let items: [Item]
    @Binding var selectedID: Item.ID?
    let title: String
    let onDelete: (Item) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title).font(.title2.bold())
                Spacer()
                Button(action: onAdd) {
                    Label("Hinzufügen", systemImage: "plus")
                }
            }
            .padding()

            List(selection: $selectedID) {
                ForEach(items) { item in
                    HStack {
                        Text(item.name).bold()
                        Spacer()
                        Button(role: .destructive) {
                            onDelete(item)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .tag(item.id)
                }
            }
        }
        .frame(minWidth: 280, maxWidth: 320)
        .background(ColorHelper.backgroundColor)
        .padding(.trailing, 8)
    }
}
#endif
