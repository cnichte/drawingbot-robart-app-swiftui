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

// MARK: - Plattformübergreifendes Image

#if os(iOS)
typealias PlatformImage = UIImage
#elseif os(macOS)
typealias PlatformImage = NSImage
#endif

// MARK: - Erweiterung für PlatformImage -> PNG-Daten

extension PlatformImage {
    func pngData() -> Data? {
        #if os(iOS)
        return self.pngData()
        #elseif os(macOS)
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
        #endif
    }
}

// MARK: - SwiftUI View zu PlatformImage

extension View {
    func snapshot(size: CGSize) -> PlatformImage {
        #if os(iOS)
        let controller = UIHostingController(rootView: self)
        controller.view.bounds = CGRect(origin: .zero, size: size)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
        #elseif os(macOS)
        let controller = NSHostingController(rootView: self)
        let view = controller.view
        view.frame = CGRect(origin: .zero, size: size)
        
        let bitmapRep = view.bitmapImageRepForCachingDisplay(in: view.bounds) ?? NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
        view.cacheDisplay(in: view.bounds, to: bitmapRep)
        
        let image = NSImage(size: size)
        image.addRepresentation(bitmapRep)
        return image
        #endif
    }
}
