//
//  Color+Hex.swift
//  Robart
//
//  Created by Carsten Nichte on 22.05.25.
//

import SwiftUI

extension Color {
    /// Initialisiert eine Color aus einem Hex-String wie "#FFAA00"
    init?(_ hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb), hexSanitized.count == 6 else {
            return nil
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    /// Gibt die Farbe als Hex-String wie "#FFAA00" zurück
    func toHexString() -> String {
#if os(macOS)
        let nsColor = NSColor(self)
        let color = nsColor.usingColorSpace(.deviceRGB) ?? nsColor
        let r = Int((color.redComponent * 255).rounded())
        let g = Int((color.greenComponent * 255).rounded())
        let b = Int((color.blueComponent * 255).rounded())
#else
        let uiColor = UIColor(self)
        guard let components = uiColor.cgColor.components else { return "#000000" }
        let r = Int((components[0] * 255).rounded())
        let g = Int((components[1] * 255).rounded())
        let b = Int((components[2] * 255).rounded())
#endif
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: Hex-String → Color
// TODO: ??? doppelt gemoppelt ???
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
