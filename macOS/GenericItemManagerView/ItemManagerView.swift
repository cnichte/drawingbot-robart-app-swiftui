//
//  AssetManagerView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

// AssetManagerView.swift
#if os(macOS)
import SwiftUI

struct ItemManagerView<Item: ManageableItem, FormView: View>: View {
    let title: String
    let createItem: () -> Item
    let buildForm: (Binding<Item>) -> FormView

    @EnvironmentObject var store: GenericStore<Item>
    @State private var selectedID: Item.ID?
    
    var body: some View {
        HStack(spacing: 0) {
            ItemListView(items: store.items,
                         selectedID: $selectedID,
                         title: title,
                         onDelete: deleteItem,
                         onAdd: addItem)
            Divider()
            formView
        }
        .frame(minWidth: 800, minHeight: 500)
        .navigationTitle(title)
    }

    private var formView: some View {
        Group {
            if let id = selectedID,
               let index = store.items.firstIndex(where: { $0.id == id }) {
                let binding = Binding(
                    get: { store.items[index] },
                    set: { newValue in
                        Task {
                            await store.save(item: newValue, fileName: "\(newValue.id)")
                        }
                    }
                )
                buildForm(binding)
                    .frame(minWidth: 500, maxWidth: .infinity)
                    .padding()
            } else {
                VStack {
                    Spacer()
                    Text("Wähle einen Eintrag aus").foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }

    private func addItem() {
        let newItem = createItem()
        Task {
            _ = await store.createNewItem(defaultItem: newItem, fileName: "\(newItem.id)")
            await MainActor.run {
                selectedID = newItem.id
            }
        }
    }

    private func deleteItem(_ item: Item) {
        if selectedID == item.id {
            selectedID = nil
        }
        Task {
            await store.delete(item: item, fileName: "\(item.id)")
        }
    }
}
#endif
