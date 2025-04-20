//
//  PaperSizeSettigsView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.
//

//  PaperSizeSettigsView.swift
import SwiftUI

struct PaperSizeSettingsView: View {
    @AppStorage("paperSizes") private var encodedSizes: Data = Data()
    @State private var paperSizes: [PaperSize] = []
    @State private var newName = ""
    @State private var newWidth: Double = 210
    @State private var newHeight: Double = 297
    @State private var newNote = ""

    var body: some View {
        Form {
            Section(header: Text("Neue Vorlage hinzufügen")) {
                TextField("Name", text: $newName)
                HStack {
                    Text("Breite (mm)")
                    TextField("", value: $newWidth, formatter: NumberFormatter())
                        .crossPlatformDecimalKeyboard()
                }
                HStack {
                    Text("Höhe (mm)")
                    TextField("", value: $newHeight, formatter: NumberFormatter())
                        .crossPlatformDecimalKeyboard()
                }
                TextField("Notiz", text: $newNote)

                Button("➕ Hinzufügen") {
                    let newSize = PaperSize(name: newName, width: newWidth, height: newHeight, orientation:0, note: newNote.isEmpty ? "" : newNote)
                    paperSizes.append(newSize)
                    save()
                    newName = ""
                    newWidth = 210
                    newHeight = 297
                    newNote = ""
                }.disabled(newName.isEmpty)
            }

            Section(header: Text("Vorlagen")) {
                if paperSizes.isEmpty {
                    Text("Keine Vorlagen vorhanden")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(paperSizes, id: \ .self) { size in
                        VStack(alignment: .leading) {
                            Text("\(size.name): \(Int(size.width))x\(Int(size.height)) mm")
                            if let note = size.note {
                                Text(note).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { indexSet in
                        paperSizes.remove(atOffsets: indexSet)
                        save()
                    }
                }
            }
        }
        .navigationTitle("Papierformate")
        .onAppear(perform: load)
    }

    private func save() {
        if let data = try? JSONEncoder().encode(paperSizes) {
            encodedSizes = data
        }
    }

    private func load() {
        if let sizes = try? JSONDecoder().decode([PaperSize].self, from: encodedSizes) {
            paperSizes = sizes
        }
    }
}

#Preview {
    NavigationView {
        PaperSizeSettingsView()
    }
}
