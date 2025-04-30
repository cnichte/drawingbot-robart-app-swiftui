//
//  JobInspectorPanel.swift
//  Robart
//
//  Created by Carsten Nichte on 27.04.25.
//

/*
 oben Ebenen, darunter Ebenen-Elemente  darunter:  properties und Robot-Comnands

 Svg properities oben Ebenen, darunter Ebenen-Elemente  darunter:  properties und Robot-Comnands
 */

// JobInspectorPanel.swift - rechter Bereich
import SwiftUI

struct JobInspectorPanel: View {
    @State private var selectedTab: InspectorTab = .fileInfo
    @Binding var selectedMachine: MachineData?
    
    // SVG-spezifische States
    @State private var layers: [SVGLayer] = []
    @State private var selectedLayer: SVGLayer? = nil
    @State private var selectedElements: [String] = []
    @State private var selectedProperties: [SVGProperty] = []
    
    enum InspectorTab: String, CaseIterable, Identifiable {
        case fileInfo = "SVG-FileInfo"
        case properties = "SVG-Properties"
        case machine = "Maschine"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tabs oben
            Picker("", selection: $selectedTab) {
                ForEach(InspectorTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 12)
            .padding(.top, 12)

            Divider()
                .padding(.horizontal, 8)
                .padding(.top, 8)

            // Inhalt je nach Tab
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .fileInfo:
                        svgFileInfoView
                    case .properties:
                        svgPropertiesView
                    case .machine:
                        machineInfoView
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.gray.opacity(0.05))
    }

    // MARK: - Inhalt für SVG-FileInfo

    @ViewBuilder
    private var svgFileInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allgemeine Datei-Informationen")
                .font(.headline)

            Text("Dateiname: (folgt)")
            Text("Dateigröße: (folgt)")
            Text("Erstellt am: (folgt)")
        }
    }

    // MARK: - Inhalt für SVG-Properties

    @ViewBuilder
    private var svgPropertiesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Abschnitt: SVG-Ebenen
            VStack(alignment: .leading, spacing: 8) {
                Text("SVG-Ebenen")
                    .font(.headline)

                if layers.isEmpty {
                    Text("Keine Ebenen gefunden")
                        .foregroundColor(.secondary)
                } else {
                    List(selection: $selectedLayer) {
                        ForEach(layers) { layer in
                            Text(layer.name)
                        }
                    }
                    .frame(height: 120)
                }
            }

            Divider()

            // MARK: -  SVG-Ebenen-Elemente
            
            VStack(alignment: .leading, spacing: 8) {
                Text("SVG-Ebenen-Elemente")
                    .font(.headline)

                if selectedElements.isEmpty {
                    Text("Keine Elemente in dieser Ebene")
                        .foregroundColor(.secondary)
                } else {
                    List(selectedElements, id: \.self) { element in
                        Text(element)
                    }
                    .frame(height: 120)
                }
            }

            Divider()

            // Abschnitt: Properties / Robot-Commands
            VStack(alignment: .leading, spacing: 8) {
                Text("Properties / Robot-Commands")
                    .font(.headline)

                if selectedProperties.isEmpty {
                    Text("Keine Properties verfügbar")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(selectedProperties) { property in
                        HStack {
                            Text(property.key)
                                .font(.subheadline)
                            Spacer()
                            Text(property.value)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    
    // MARK: - Inhalt für Maschinen-Details
    
    @ViewBuilder
    private var machineInfoView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let selectedMachine = selectedMachine {
                Text("Maschinenname: \(selectedMachine.name)")
                    .font(.headline)
                Text("Typ: \(selectedMachine.typ.rawValue)")
                Text("Protokoll: \(selectedMachine.commandProtocol)")
                Text("Größe: \(selectedMachine.size.x) x \(selectedMachine.size.y) mm")
                Text("Verbunden: \(selectedMachine.isConnected ? "Ja" : "Nein")")

                Divider()

                // CodeTemplates anzeigen
                Text("CodeTemplates:")
                ForEach(selectedMachine.commandItems, id: \.id) { template in
                    VStack(alignment: .leading) {
                        Text("Befehl: \(template.command)")
                        Text("Beschreibung: \(template.description)")
                    }
                    .padding(.bottom, 4)
                }

                Divider()

                // Optionen anzeigen
                Text("Optionen:")
                ForEach(selectedMachine.options, id: \.id) { option in
                    VStack(alignment: .leading) {
                        Text("Option: \(option.option)")
                        Text("Wert: \(option.valueAsString)")
                    }
                    .padding(.bottom, 4)
                }
            } else {
                Text("Keine Maschine ausgewählt.")
            }
        }
    }
}

// MARK: - Hilfs-Modelle

struct SVGLayer: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

struct SVGProperty: Identifiable {
    let id = UUID()
    let key: String
    let value: String
}
