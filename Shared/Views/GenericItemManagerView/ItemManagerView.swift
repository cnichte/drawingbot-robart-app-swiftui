//
//  ItemManagerView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

// ItemManagerView.swift
import SwiftUI

struct ItemManagerView<Item: ManageableItem, FormView: View>: View {
    let title: String
    let createItem: () -> Item
    let buildForm: (Binding<Item>) -> FormView

    @EnvironmentObject var store: GenericStore<Item>
    @State private var selectedID: UUID?

    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }

    // MARK: - macOS Layout (unverändert)
    private var macOSLayout: some View {
        HStack(spacing: 0) {
            listView
            Divider()
            if let binding = selectedItemBinding {
                buildForm(binding)
                    .frame(minWidth: 500, maxWidth: .infinity)
                    .padding()
            } else {
                emptyDetailView
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .navigationTitle(title)
    }

    // MARK: - iOS Layout (NavigationStack mit Push)
    private var iOSLayout: some View {
        NavigationStack {
            List {
                ForEach(store.items) { item in
                    NavigationLink {
                        if let binding = binding(for: item.id) {
                            buildForm(binding)
                        }
                    } label: {
                        Text(item.displayName)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            confirmDelete(item)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                }

                Button {
                    addNewItem()
                } label: {
                    Label("Neuen Eintrag hinzufügen", systemImage: "plus")
                        .foregroundColor(.accentColor)
                }
            }
            .navigationTitle(title)
        }
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
                        Text(item.displayName).bold()
                        Spacer()
                        Button(role: .destructive) {
                            confirmDelete(item)
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

    

    // MARK: - Binding-Hilfen
    private var selectedItemBinding: Binding<Item>? {
        guard let id = selectedID else { return nil }
        return binding(for: id)
    }

    private func binding(for id: UUID) -> Binding<Item>? {
        guard let index = store.items.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding<Item>(
            get: { store.items[index] },
            set: { newValue in
                Task {
                    await store.save(item: newValue, fileName: newValue.id.uuidString)
                }
            }
        )
    }

    // MARK: - Aktionen
    private func addNewItem() {
        let newItem = createItem()
        Task {
            _ = await store.createNewItem(defaultItem: newItem, fileName: newItem.id.uuidString)

            // Warten, bis Item im Store auftaucht (für iOS Push Navigation nötig)
            while !store.items.contains(where: { $0.id == newItem.id }) {
                try? await Task.sleep(nanoseconds: 20_000_000)
            }

            await MainActor.run {
                selectedID = newItem.id
            }
        }
    }

    private func confirmDelete(_ item: Item) {
        #if os(macOS)
        let alert = NSAlert()
        alert.messageText = "Eintrag löschen?"
        alert.informativeText = "\"\(item.displayName)\" wirklich löschen?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Löschen")
        alert.addButton(withTitle: "Abbrechen")
        if alert.runModal() == .alertFirstButtonReturn {
            delete(item)
        }
        #else
        delete(item)
        #endif
    }

    private func delete(_ item: Item) {
        if selectedID == item.id {
            selectedID = nil
        }
        Task {
            await store.delete(item: item, fileName: item.id.uuidString)
        }
    }

    private var emptyDetailView: some View {
        VStack {
            Spacer()
            Text("Wähle einen Eintrag aus")
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
