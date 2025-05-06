//
//  ColorHelper.swift
//  Robart
//
//  Created by Carsten Nichte on 05.05.25.
//
import SwiftUI

// MARK: - Farb-Hilfen
struct ColorHelper {
    static var backgroundColor: Color {
#if os(iOS)
        return Color(.secondarySystemBackground)
#elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
#endif
    }
}
