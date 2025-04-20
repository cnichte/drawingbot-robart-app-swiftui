//
//  PenManagerView.swift
//  Robart
//
//  Created by Carsten Nichte on 20.04.25.
//

import SwiftUI

struct PenManagerView: View {
    @EnvironmentObject var penStore: GenericStore<PenData>
    @State private var selectedPenID: UUID? = nil

    var body: some View {
        NavigationStack {
            #if os(iOS)
            iOSLayout
            #else
            macOSLayout
            #endif
        }
    }

    // MARK: macOS
    private var macOSLayout: some View {
        HStack(spacing: 0) {
            PenListView(
                pens: penStore.items,
                selectedPenID: $selectedPenID,
                onDelete: confirmDeletion,
                onAdd: addNewPen
            )
            Divider()
            if let binding = selectedPenBinding {
                PenFormView(pen: binding) {}
                    .frame(minWidth: 500, maxWidth: .infinity)
                    .padding()
            } else {
                VStack {
                    Spacer()
                    Text("Wähle einen Stift aus").foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .navigationTitle("Stifte verwalten")
    }

    // MARK: iOS
    private var iOSLayout: some View {
        Group {
            if let binding = selectedPenBinding {
                PenFormView(pen: binding) {
                    selectedPenID = nil
                }
            } else {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Stifte").font(.title2.bold())
                        Spacer()
                        Button(action: addNewPen) {
                            Label("Stift hinzufügen", systemImage: "plus")
                        }
                    }
                    .padding([.horizontal, .top])

                    List {
                        ForEach(penStore.items) { pen in
                            HStack {
                                Button {
                                    selectedPenID = pen.id
                                } label: {
                                    Text(pen.name).bold()
                                }
                                Spacer()
                                Button(role: .destructive) {
                                    confirmDeletion(pen)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Stifte verwalten")
    }

    private var selectedPenBinding: Binding<PenData>? {
        guard let id = selectedPenID,
              let index = penStore.items.firstIndex(where: { $0.id == id }) else {
            if selectedPenID != nil {
                DispatchQueue.main.async {
                    selectedPenID = nil
                }
            }
            return nil
        }

        return Binding<PenData>(
            get: { penStore.items[index] },
            set: { newValue in
                Task {
                    await penStore.save(item: newValue, fileName: newValue.id.uuidString)
                }
            }
        )
    }

    private func confirmDeletion(_ pen: PenData) {
        #if os(macOS)
        let alert = NSAlert()
        alert.messageText = "Stift löschen?"
        alert.informativeText = "Möchtest du den Stift „\(pen.name)“ wirklich löschen?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Löschen")
        alert.addButton(withTitle: "Abbrechen")
        if alert.runModal() == .alertFirstButtonReturn {
            Task {
                await penStore.delete(item: pen, fileName: pen.id.uuidString)
            }
        }
        #endif
    }

    private func addNewPen() {
        let pen = PenData(name: "Neuer Stift")
        Task {
            _ = await penStore.createNewItem(defaultItem: pen, fileName: pen.id.uuidString)
        }
    }
}
