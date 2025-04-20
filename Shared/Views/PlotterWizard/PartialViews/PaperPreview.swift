//
//  PaperPreview.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.
//

//  PaperPreview.swift
import SwiftUI
import SVGView

struct PaperPreview: View {
    @Binding var zoom: Double
    @Binding var pitch: Double
    @Binding var origin: CGPoint
    var job: PlotJobData?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let job = job {
                    let paperWidth = CGFloat(job.paperSize.width)
                    let paperHeight = CGFloat(job.paperSize.height)
                    let scaleFactor = min(geo.size.width / paperWidth, geo.size.height / paperHeight)

                    let paperFrame = CGSize(width: paperWidth * scaleFactor, height: paperHeight * scaleFactor)

                    // Hintergrund (Papier)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: paperFrame.width, height: paperFrame.height)
                        .border(Color.black, width: 1)

                    // SVG über das Papier legen
                    if !job.svgFilePath.isEmpty {
                        SVGView(contentsOf: URL(fileURLWithPath: job.svgFilePath))
                            .scaleEffect(CGFloat(zoom)) // Zoom anwenden
                            .rotationEffect(.degrees(pitch)) // Pitch anwenden
                            .offset(x: origin.x, y: origin.y)
                            .frame(width: paperFrame.width, height: paperFrame.height)
                            .clipped()
                    } else {
                        Text("SVG fehlt")
                            .foregroundColor(.red)
                    }
                } else {
                    Text("Kein aktiver Job")
                        .foregroundColor(.red)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity) // Maximale Breite und Höhe einnehmen
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        origin = CGPoint(x: value.translation.width, y: value.translation.height)
                    }
            )
            .frame(maxWidth: .infinity, alignment: .center) // Hier setzen wir den Inhalt horizontal auf der gesamten Breite
        }
    }
}
