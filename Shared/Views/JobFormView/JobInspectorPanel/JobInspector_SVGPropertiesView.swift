//
//  JobInspector_SVGPropertiesView.swift
//  Robart
//
//  Created by Carsten Nichte on 01.05.25.
//

// JobInspector_SVGPropertiesView.swift
import SwiftUI

struct JobInspector_SVGPropertiesView: View {
    @Binding var currentJob: JobData
    
    @Binding var layers: [SVGLayer]
    @Binding var selectedLayer: SVGLayer?
    @Binding var selectedElements: [String]
    @Binding var selectedProperties: [SVGProperty]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
}
