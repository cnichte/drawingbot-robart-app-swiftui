//
//  TabManagerView.swift
//  Robart
//
//  Created by Carsten Nichte on 20.04.25.
//

// TabManagerView.swift (nur für macOS)
#if os(macOS)
import SwiftUI
import AppKit

// protocol TabManageable: Identifiable, Codable, Equatable where ID == UUID {
//    var name: String { get }
// }


// alternative lösung:  struct TabManagerView<Item: ManageableItem, FormView: View>: View where Item.ID == UUID {
struct TabManagerView<Item: ManageableItem & Identifiable<UUID>, FormView: View>: View {

    let title: String
    let formBuilder: (Binding<Item>) -> FormView
    
    @EnvironmentObject var store: GenericStore<Item>
    
    @State private var selectedID: UUID?

    var body: some View {
        HStack(spacing: 0) {
            listView
            Divider()
            formView
        }
        .frame(minWidth: 800, minHeight: 500)
        .navigationTitle(title)
    }

    private var listView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.title2.bold())
                Spacer()
                Button(action: addNewItem) {
                    Label("Hinzufügen", systemImage: "plus")
                }
            }
            .padding()

            List(selection: $selectedID) {
                ForEach(store.items) { item in
                    HStack {
                        Text(item.name).bold()
                        Spacer()
                        Button(role: .destructive) {
                            delete(item)
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

    private var formView: some View {
        Group {
            if let id = selectedID,
               let index = store.items.firstIndex(where: { $0.id == id }) {
                let binding = Binding(
                    get: { store.items[index] },
                    set: { newValue in
                        Task {
                            await store.save(item: newValue, fileName: newValue.id.uuidString)
                        }
                    }
                )
                formBuilder(binding)
                    .frame(minWidth: 500, maxWidth: .infinity)
                    .padding()
            } else {
                VStack {
                    Spacer()
                    Text("Wähle einen Eintrag aus")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func addNewItem() {
        let newItem = createDefaultItem()
        Task {
            _ = await store.createNewItem(defaultItem: newItem, fileName: newItem.id.uuidString)
            await MainActor.run {
                self.selectedID = newItem.id
            }
        }
    }

    private func delete(_ item: Item) {
        if selectedID == item.id {
            selectedID = nil
        }
        Task {
            await store.delete(item: item, fileName: item.id.uuidString)
        }
    }

    private func createDefaultItem() -> Item {
        fatalError("createDefaultItem() muss überschrieben werden")
    }
}
#endif
