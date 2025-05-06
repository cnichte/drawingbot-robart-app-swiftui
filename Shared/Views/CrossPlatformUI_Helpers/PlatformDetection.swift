//
//  PlatformDetection.swift
//  Robart
//
//  Created by Carsten Nichte on 05.05.25.
//
import SwiftUI

struct PlatformDetection {
    static var isiOS: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    static var isMacOS: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Bildschirmgrößen

struct ScreenHelper {
    static var width: CGFloat {
#if os(iOS)
        return UIScreen.main.bounds.width
#elseif os(macOS)
        return NSScreen.main?.visibleFrame.width ?? 0
#endif
    }
    
    static var height: CGFloat {
#if os(iOS)
        return UIScreen.main.bounds.height
#elseif os(macOS)
        return NSScreen.main?.visibleFrame.height ?? 0
#endif
    }
}
