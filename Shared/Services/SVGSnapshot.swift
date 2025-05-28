//
//  SVGSnapshot.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// SVGSnapshot.swift
// Hilfsfunktionen für Snapshot/Thumbnail von SVG und SwiftUI Views
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - PlattformImage
#if os(iOS)
typealias PlatformImage = UIImage
#elseif os(macOS)
typealias PlatformImage = NSImage
#endif

// MARK: - PNG-Erweiterung für macOS
#if os(macOS)
extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }
}
#endif

// MARK: - SVGSnapshot
struct SVGSnapshot {
    /// Generischer SwiftUI-Snapshot
    static func snapshot<V: View>(of view: V, size: CGSize) -> PlatformImage? {
        #if os(macOS)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = CGRect(origin: .zero, size: size)
        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            return nil
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        let image = NSImage(size: size)
        image.addRepresentation(bitmap)
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

    /// Speichert ein PlatformImage als PNG
    static func saveThumbnail(_ image: PlatformImage, to url: URL) throws {
        #if os(macOS)
        guard let data = image.pngData() else {
            throw NSError(domain: "SnapshotError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "PNG-Konvertierung fehlgeschlagen"])
        }
        try data.write(to: url)
        #else
        guard let data = image.pngData() else {
            throw NSError(domain: "SnapshotError", code: 1001, userInfo: [NSLocalizedDescriptionKey: "PNG-Konvertierung fehlgeschlagen"])
        }
        try data.write(to: url)
        #endif
    }
}
