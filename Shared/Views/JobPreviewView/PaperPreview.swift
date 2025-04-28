//
//  PaperPreview.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 11.04.25.
//

// PaperPreview.swift
import SwiftUI
import SVGView

struct PaperPreview: View {
    @Binding var zoom: Double
    @Binding var pitch: Double
    @Binding var origin: CGPoint
    @Binding var job: PlotJobData

    var body: some View {
        GeometryReader { geo in
            ZStack {
                let paperWidth = CGFloat(job.paper.paperFormat.width)
                let paperHeight = CGFloat(job.paper.paperFormat.height)
                let scaleFactor = min(geo.size.width / paperWidth, geo.size.height / paperHeight)

                let paperFrame = CGSize(width: paperWidth * scaleFactor, height: paperHeight * scaleFactor)

                Rectangle()
                    .fill(Color.white)
                    .frame(width: paperFrame.width, height: paperFrame.height)
                    .border(Color.black, width: 1)

                if let svgURL = resolveSVGURL() {
                    SVGView(contentsOf: svgURL)
                        .scaleEffect(CGFloat(zoom))
                        .rotationEffect(.degrees(pitch))
                        .offset(x: origin.x, y: origin.y)
                        .frame(width: paperFrame.width, height: paperFrame.height)
                        .clipped()
                        .onAppear {
                            ensureFileIsDownloaded(url: svgURL)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        origin = CGPoint(x: value.translation.width, y: value.translation.height)
                    }
            )
        }
    }

    private func resolveSVGURL() -> URL? {
        guard !job.svgFilePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        do {
            let documentsURL = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            let fullURL = documentsURL.appendingPathComponent(job.svgFilePath)
            if FileManager.default.fileExists(atPath: fullURL.path) {
                return fullURL
            } else {
                return nil
            }
        } catch {
            appLog("❌ Fehler beim Ermitteln des Documents-Pfads: \(error)")
            return nil
        }
    }

    private func ensureFileIsDownloaded(url: URL) {
        do {
            let values = try url.resourceValues(forKeys: [.isUbiquitousItemKey])
            if values.isUbiquitousItem == true {
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
                appLog("📥 Download gestartet für \(url.lastPathComponent)")
            }
        } catch {
            appLog("⚠️ Fehler beim Überprüfen/Starten des Downloads: \(error)")
        }
    }
}
