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

    private var layersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SVG-Gruppen").font(.headline)
            if model.layers.isEmpty {
                Text("Keine Gruppe gefunden").foregroundColor(.secondary)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(model.layers, id: \.id) { layer in
                            HStack {
                                Text(layer.name)
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { model.selectedLayer = layer }
                            .background(
                                model.selectedLayer == layer
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                            )
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 120)
#if os(macOS)
                .listStyle(.inset)
#endif
            }
        }
    }
    
    private var elementsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SVG-Gruppen Elemente").font(.headline)
            if model.elementsInSelectedLayer.isEmpty {
                Text("Keine Elemente in dieser Gruppe").foregroundColor(.secondary)
            } else {
                List(model.elementsInSelectedLayer, id: \.id) { item in
                    HStack {
                        Text(item.element.name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { model.selectedElement = item }
                    .background(
                        model.selectedElement == item
                        ? Color.accentColor.opacity(0.2)
                        : Color.clear
                    )
                }
                .frame(height: 120)
#if os(macOS)
                .listStyle(.inset)
#endif
            }
        }
    }
    
    private var propertiesSection: some View {
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
    }
    
    private var gcodeSection: some View {
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
                Text("Kein Element ausgewählt").foregroundColor(.secondary)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SVGStatistikView(statistic: model.statistic)
            SVGParserProgressView()
                .environmentObject(model)
            Divider()
            layersSection
            Divider()
            elementsSection
            Divider()
            propertiesSection
            Divider()
            gcodeSection
        }
        .onAppear {
            /*
             TODO: Das soll in SVGSectionView erfolgen, wenn ein SVG ausgewählt wird.
             TODO: ODER beim öffnen von JobFormView (wenn noch nie geparst wurde),
             TODO: ODER wenn die Maschine ODER das Papier ODER die Stifte gewechselt werden,
             TODO: ODER Transfomationen im PaperPanel gemacht wurden! - also immer dann wenn nötig.
             */
            appLog(.info, "JobInspector_SVGPropertiesView appeared, layers: \(model.layers.count)")
            if model.layers.isEmpty && !model.job.svgFilePath.isEmpty {
                Task { @MainActor in
                    appLog(.info, "Initial SVG parsing triggered.")
                    await model.loadAndParseSVG()
                }
            }
            
        }
        .onChange(of: model.layers) { _, newLayers in
            appLog(.info, "Layers updated, count: \(newLayers.count)")
        }
        .onChange(of: model.allElements) { _, newElements in
            appLog(.info, "AllElements updated, count: \(newElements.count)")
        }
    }
}

struct SVGStatistikView: View {
    let statistic: SVGParserStatistic?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SVG Statistik").font(.headline)
            if let stat = statistic {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Größe: \(Int(stat.svgWidth ?? 0)) x \(Int(stat.svgHeight ?? 0))")
                    Text("Layer: \(stat.svgLayerCount)")
                    Text("Elemente: \(stat.svgElementCount)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            } else {
                Text("Keine Statistik verfügbar").foregroundColor(.secondary)
            }
        }
    }
}

struct SVGParserProgressView: View {
    @EnvironmentObject var model: SVGInspectorModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SVG Parsing Fortschritt").font(.headline)
                Spacer()
                if model.progress > 0 && model.progress < 1.0 {
                    Button(action: {
                        model.cancelParsing()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
            
            ProgressView(value: model.progress, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .animation(.easeInOut(duration: 0.3), value: model.progress)
            
            if model.progress == 0 || model.progress >= 1.0 {
                Button("SVG erneut analysieren") {
                    Task { await model.loadAndParseSVG() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

extension Notification.Name {
    static let cancelSVGParsing = Notification.Name("cancelSVGParsing")
    static let triggerSVGParsing = Notification.Name("triggerSVGParsing")
}
