//
//  MachineFormView.swift
//  Robart
//
//  Created by Carsten Nichte on 22.04.25.
//

// MachineFormView.swift
import SwiftUI

struct MachineFormView: View {
    @Binding var data: MachineData
    @EnvironmentObject var store: GenericStore<MachineData>

    @State private var optionSearchText = ""
    @State private var optionsExpanded = true

    @State private var codeTemplateSearchText = ""
    @State private var codeTemplatesExpanded = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                detailsSection
                sizeSection
                machineCommandsSection
                machineOptionsSection
            }
            .padding()
        }
        .navigationTitle("Maschine bearbeiten")
        .onReceive(store.$refreshTrigger) { _ in }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        CollapsibleSection(title: "Details", systemImage: "info.circle", toolbar: { EmptyView() }) {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Name", text: $data.name)
                    .platformTextFieldModifiers()
                    .onChange(of: data.name) { save() }

                TextEditor(text: $data.description)
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2))
                    )
                    .onChange(of: data.description) { save() }

                Picker("Typ", selection: $data.typ) {
                    ForEach(MachineType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: data.typ) { save() }
                
                HStack {
                    Text("Anzahl der Stifte")
                    MF_Tools.intTextField(label: "Anzahl Stifte", value: $data.penCount)
                }
                .onChange(of: data.size.x) { save() }
            }
        }
    }

    // MARK: - Size Section

    private var sizeSection: some View {
        CollapsibleSection(title: "Größe", systemImage: "ruler", toolbar: { EmptyView() }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Breite")
                    MF_Tools.doubleTextField(label: "Breite", value: $data.size.x)
                }
                .onChange(of: data.size.x) { save() }

                HStack {
                    Text("Höhe")
                    MF_Tools.doubleTextField(label: "Höhe", value: $data.size.y)
                }
                .onChange(of: data.size.y) { save() }
            }
        }
    }

    // MARK: - Machine-Commands Section

    private var machineCommandsSection: some View {
        CollapsibleSection(
            title: "Machine Commands",
            systemImage: "doc.plaintext",
            toolbar: {
                HStack(spacing: 8) {
                    TextField("Suchen …", text: $codeTemplateSearchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)

                    Button(action: {
                        data.commandItems.append(MachineCommandItem(name:"", command: "", description: ""))
                        save()
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }
        ) {
            VStack(spacing: 8) {
                ForEach(filteredTemplates) { $template in
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Command", text: $template.command)
                        TextField("Beschreibung", text: $template.description)
                    }
                    .padding(8)
                    .background(ColorHelper.backgroundColor)
                    .cornerRadius(8)
                    .onChange(of: template) { save() }
                }
                .onDelete { indices in
                    data.commandItems.remove(atOffsets: indices)
                    save()
                }
            }
        }
    }

    private var filteredTemplates: [Binding<MachineCommandItem>] {
        $data.commandItems.filter { binding in
            codeTemplateSearchText.isEmpty || binding.wrappedValue.command.localizedCaseInsensitiveContains(codeTemplateSearchText)
        }
    }

    // MARK: - Machine-Options Section

    private var machineOptionsSection: some View {
        CollapsibleSection(
            title: "Optionen",
            systemImage: "slider.horizontal.3",
            toolbar: {
                HStack(spacing: 8) {
                    TextField("Suchen …", text: $optionSearchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)

                    Button(action: {
                        data.options.append(MachineOption(option: "", value: .string(""), description: ""))
                        save()
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.borderless)
                }
            }
        ) {
            VStack(spacing: 8) {
                ForEach(filteredOptions) { $option in
                    VStack(alignment: .leading, spacing: 6) {
                        TextField("Option", text: $option.option)
                        TextField("Wert", text: Binding(
                            get: { option.valueAsString },
                            set: { option.valueAsString = $0 }
                        ))
                        TextField("Beschreibung", text: $option.description)
                    }
                    .padding(8)
                    .background(ColorHelper.backgroundColor)
                    .cornerRadius(8)
                    .onChange(of: option) { save() }
                }
                .onDelete { indices in
                    data.options.remove(atOffsets: indices)
                    save()
                }
            }
        }
    }

    private var filteredOptions: [Binding<MachineOption>] {
        $data.options.filter { binding in
            optionSearchText.isEmpty || binding.wrappedValue.option.localizedCaseInsensitiveContains(optionSearchText)
        }
    }

    private func save() {
        Task {
            await store.save(item: data, fileName: data.id.uuidString)
        }
    }
}

// MARK: - Tools

struct MF_Tools {
    static func doubleTextField(label: String, value: Binding<Double>) -> some View {
        TextField(label, value: value, format: .number)
            .textFieldStyle(.roundedBorder)
    }
    
    static func intTextField(label: String, value: Binding<Int>) -> some View {
        TextField(label, value: value, format: .number)
            .textFieldStyle(.roundedBorder)
    }
}
