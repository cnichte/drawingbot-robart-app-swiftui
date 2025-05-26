//
//  PaperPanel.swift
//  Robart
//
//  Created by Carsten Nichte on 11.04.25.
//

// PaperPanel.swift
import SwiftUI
import SVGView

struct PaperPanel: View {
    @EnvironmentObject var model: SVGInspectorModel

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1) Papier-Orientierung & Maßstab
                let isLandscape = model.job.paperOrientation == .landscape
                let widthUnits  = isLandscape
                    ? model.job.paperData.paperFormat.height
                    : model.job.paperData.paperFormat.width
                let heightUnits = isLandscape
                    ? model.job.paperData.paperFormat.width
                    : model.job.paperData.paperFormat.height

                let paperSize    = CGSize(width: CGFloat(widthUnits), height: CGFloat(heightUnits))
                let scaleFactor  = min(geo.size.width / paperSize.width,
                                       geo.size.height / paperSize.height)
                let paperFrame   = CGSize(width: paperSize.width * scaleFactor,
                                          height: paperSize.height * scaleFactor)
                let unitsLabel   = "mm" // TODO: model.job.paperData.unitsData?.name ?? "mm"

                // ruler configuration
                let rulerThickness: CGFloat = 20
                let rulerGap: CGFloat = 5

                // Bindings über JobBox
                let zoomBinding = Binding<Double>(
                    get: { model.jobBox.zoom },
                    set: { newZoom in
                        model.jobBox.zoom = newZoom
                        model.syncJobBoxBack()
                    })
                let pitchBinding = Binding<Double>(
                    get: { model.jobBox.pitch },
                    set: { newPitch in
                        model.jobBox.pitch = newPitch
                        model.syncJobBoxBack()
                    })

                // 2) Hintergrund-Papier mit Farbe, Rand und Schatten
                Rectangle()
                    .fill(Color(hex: model.job.paperData.color))
                    .frame(width: paperFrame.width, height: paperFrame.height)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 5, y: 5)
                    .overlay(
                        Rectangle().stroke(Color.black, lineWidth: 1)
                    )

                // 3) Ruler oben
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    Canvas { context, size in
                        for i in stride(from: 0.0, through: widthUnits, by: 10.0) {
                            let x = CGFloat(i) * scaleFactor
                            var tick = Path()
                            let h: CGFloat = (i.truncatingRemainder(dividingBy: 50) == 0) ? 15 : 10
                            tick.move(to: CGPoint(x: x, y: size.height))
                            tick.addLine(to: CGPoint(x: x, y: size.height - h))
                            context.stroke(tick, with: .color(.black), lineWidth: 1)
                            if i.truncatingRemainder(dividingBy: 50) == 0 {
                                let txt = Text("\(Int(i))\(unitsLabel)")
                                    .font(.caption2)
                                    .foregroundColor(.black)
                                context.draw(txt,
                                             at: CGPoint(x: x + 2, y: size.height - h - 2),
                                             anchor: .bottomLeading)
                            }
                        }
                    }
                }
                .frame(width: paperFrame.width, height: rulerThickness)
                .cornerRadius(4)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .offset(x: 0, y: -(paperFrame.height/2 + rulerThickness/2 + rulerGap))

                // 4) Ruler links
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    Canvas { context, size in
                        for i in stride(from: 0.0, through: heightUnits, by: 10.0) {
                            let y = CGFloat(i) * scaleFactor
                            var tick = Path()
                            let w: CGFloat = (i.truncatingRemainder(dividingBy: 50) == 0) ? 15 : 10
                            tick.move(to: CGPoint(x: size.width, y: y))
                            tick.addLine(to: CGPoint(x: size.width - w, y: y))
                            context.stroke(tick, with: .color(.black), lineWidth: 1)
                            if i.truncatingRemainder(dividingBy: 50) == 0 {
                                let txt = Text("\(Int(i))\(unitsLabel)")
                                    .font(.caption2)
                                    .foregroundColor(.black)
                                context.draw(txt,
                                             at: CGPoint(x: size.width - w - 2, y: y + 2),
                                             anchor: .topTrailing)
                            }
                        }
                    }
                }
                .frame(width: rulerThickness, height: paperFrame.height)
                .cornerRadius(4)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .offset(x: -(paperFrame.width/2 + rulerThickness/2 + rulerGap), y: 0)

                // 5) SVG-Inhalt mit Pan/Zoom/Rotate
                if let svgURL = resolveSVGURL() {
                    SVGView(contentsOf: svgURL)
                        .scaleEffect(CGFloat(model.jobBox.zoom))
                        .rotationEffect(.degrees(model.jobBox.pitch))
                        .offset(x: model.jobBox.origin.x, y: model.jobBox.origin.y)
                        .frame(width: paperFrame.width, height: paperFrame.height)
                        .clipped()
                        .onAppear {
                            ensureFileIsDownloaded(url: svgURL)
                        }
                }

                // 6) Overlay-Steuerung (Zoom + Drehung)
                VStack(spacing: 8) {
                    HStack {
                        Text("Zoom:")
                        Slider(value: zoomBinding, in: 0.05...2.0)
                        TextField("", value: zoomBinding,
                                  format: .number.precision(.fractionLength(2)))
                            .frame(width: 50)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack {
                        Text("Drehung:")
                        Slider(value: pitchBinding, in: 0...360)
                        TextField("", value: pitchBinding,
                                  format: .number.precision(.fractionLength(0)))
                            .frame(width: 50)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
                .foregroundColor(.white)
                .offset(x: 0, y: paperFrame.height / 2 - 60)
                .opacity(0.8)
            }
            // Gesamt-Frame & Pan-Gesture
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { val in
                        model.jobBox.origin = CGPoint(x: val.translation.width,
                                                      y: val.translation.height)
                        model.syncJobBoxBack()
                    }
            )
            .padding(20) // Rand um das Papier
        }
    }

    // MARK: - Helpers

    private func resolveSVGURL() -> URL? {
        guard !model.job.svgFilePath.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        do {
            let docs = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil, create: false)
            let full = docs.appendingPathComponent(model.job.svgFilePath)
            return FileManager.default.fileExists(atPath: full.path) ? full : nil
        } catch {
            appLog(.info, "❌ Fehler beim Documents-Pfad: \(error)")
            return nil
        }
    }

    private func ensureFileIsDownloaded(url: URL) {
        do {
            let vals = try url.resourceValues(forKeys: [.isUbiquitousItemKey])
            if vals.isUbiquitousItem == true {
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
                appLog(.info, "📥 Download gestartet: \(url.lastPathComponent)")
            }
        } catch {
            appLog(.info, "⚠️ Download-Check-Fehler: \(error)")
        }
    }
}

// Hex-String → Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        if hex.count == 6 {
            (r, g, b) = ((int >> 16) & 0xFF,
                         (int >> 8)  & 0xFF,
                         int         & 0xFF)
        } else {
            (r, g, b) = (255, 255, 255)
        }
        self.init(
            red:   Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue:  Double(b) / 255.0)
    }
}
