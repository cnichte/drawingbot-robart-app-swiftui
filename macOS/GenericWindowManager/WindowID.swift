//
//  WindowID.swift
//  Robart
//
//  Created by Carsten Nichte on 17.04.25.
//

// WindowID.swift
import Foundation
#if os(macOS)
/// Typsichere IDs für Fensterverwaltungsfunktionen unter macOS
enum WindowID: String {
    case assetManager
    
    case connectionAssetManager
    case machineAssetManager
    case paperAssetManager
    case penAssetManager
    case projectManager
    
    case jobDetail
    case settings
    // Weitere Fenster-IDs hier hinzufügen
}
#endif
