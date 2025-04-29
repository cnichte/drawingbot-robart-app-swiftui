//
//  SVGSnapshot.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// SVGSnapshot.swift
// Hilfsfunktionen für Snapshot/Thumbnail von SVG und SwiftUI Views

import SwiftUI
import SVGView
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Plattformübergreifendes Image

#if os(iOS)
typealias PlatformImage = UIImage
#elseif os(macOS)
typealias PlatformImage = NSImage
#endif

// MARK: - Erweiterung für PlatformImage -> PNG-Daten

#if os(macOS)
extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}
#endif

// MARK: - SVGSnapshot

struct SVGSnapshot {

    /// Erzeugt ein Thumbnail aus einem SwiftUI View
    static func snapshot<V: View>(of view: V, size: CGSize) -> PlatformImage? {
        #if os(macOS)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: size)

        guard let bitmapRep = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return nil
        }

        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmapRep)

        let image = NSImage(size: size)
        image.addRepresentation(bitmapRep)
        return image
        #else
        let controller = UIHostingController(rootView: view)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            controller.view.layer.render(in: ctx.cgContext)
        }
        #endif
    }

    /// Speichert ein PlatformImage als PNG-Datei
    static func saveThumbnail(_ image: PlatformImage, to url: URL) throws {
        #if os(macOS)
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "SnapshotError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "PNG-Konvertierung fehlgeschlagen"])
        }
        try pngData.write(to: url)
        #else
        guard let pngData = image.pngData() else {
            throw NSError(domain: "SnapshotError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "PNG-Konvertierung fehlgeschlagen"])
        }
        try pngData.write(to: url)
        #endif
    }

    /// Erzeugt direkt ein Thumbnail aus einer SVG-Datei (SVGView)
    static func generateThumbnail(from svgURL: URL, maxSize: CGSize) async -> PlatformImage? {
        return await MainActor.run {
            let view = SVGView(contentsOf: svgURL)
                .frame(width: maxSize.width, height: maxSize.height)

            return SVGSnapshot.snapshot(of: view, size: maxSize)
        }
    }
}
