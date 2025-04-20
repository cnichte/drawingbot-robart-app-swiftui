//
//  WindowID.swift
//  Robart
//
//  Created by Carsten Nichte on 17.04.25.
//

import Foundation

#if os(macOS)
/// Typsichere IDs für Fensterverwaltungsfunktionen unter macOS
enum WindowID: String {
    case projectEditor
    case jobDetail
    case settings
    // Weitere Fenster-IDs hier hinzufügen
}
#endif
