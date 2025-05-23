//
//  JobInspector_SVGPropertiesView.swift
//  Robart
//
//  Created by Carsten Nichte on 01.05.25.
//

// JobInspector_SVGPropertiesView.swift
import SwiftUI

struct JobInspector_SVGPropertiesView: View {
    @EnvironmentObject var model: SVGInspectorModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SVG-Ebenen").font(.headline)

                if model.layers.isEmpty {
                    Text("Keine Ebenen gefunden").foregroundColor(.secondary)
                } else {
                    List(model.layers, id: \.id, selection: $model.selectedLayer) { layer in
                        HStack {
                            Text(layer.name)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            model.selectedLayer = layer
                        }
                        .background(
                            (model.selectedLayer == layer ? Color.accentColor.opacity(0.2) : Color.clear)
                        )
                    }
                    .frame(height: 120)
                    #if os(macOS)
                    .listStyle(.inset)
                    #endif
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("SVG-Ebenen-Elemente").font(.headline)

                if model.elementsInSelectedLayer.isEmpty {
                    Text("Keine Elemente in dieser Ebene").foregroundColor(.secondary)
                } else {
                    List(model.elementsInSelectedLayer, id: \.id) { item in
                        HStack {
                            Text(item.element.name)
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            model.selectedElement = item
                        }
                        .background(
                            (model.selectedElement == item ? Color.accentColor.opacity(0.2) : Color.clear)
                        )
                    }
                    .frame(height: 120)
                    #if os(macOS)
                    .listStyle(.inset)
                    #endif
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("SVG-Properties").font(.headline)

                if model.selectedProperties.isEmpty {
                    Text("Keine Properties verfügbar").foregroundColor(.secondary)
                } else {
                    ForEach(model.selectedProperties) { property in
                        HStack {
                            Text(property.key).font(.subheadline)
                            Spacer()
                            Text(property.value).foregroundColor(.secondary)
                        }
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("G-Code für Auswahl").font(.headline)

                if let _ = model.selectedElement {
                    ScrollView {
                        Text(model.gcodeForSelectedElement())
                            .font(.system(size: 12, design: .monospaced))
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .frame(height: 160)
                } else {
                    Text("Kein Element ausgewählt")
                        .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            if model.layers.isEmpty {
                Task {
                    await model.loadAndParseSVG()
                }
            }
        }
    }
}
