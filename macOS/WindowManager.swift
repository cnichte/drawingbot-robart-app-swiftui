//
//  WindowManager.swift
//  Robart
//
//  Created by Carsten Nichte on 17.04.25.
//

// Beispiel:
//
// WindowManager.shared.openWithEnvironmentObjects(
//     ProjectEditorView(),
//     id: .projectEditor,
//     title: "Projekte verwalten",
//     width: 900,
//     height: 600,
//     environmentObjects: [
//         EnvironmentObjectModifier(object: projectStore),
//         EnvironmentObjectModifier(object: plotJobStore)
//     ]
// )


// WindowManager.swift (final and complete version for macOS)
/*
#if os(macOS)
import SwiftUI
import AppKit

// EnvironmentObject-Wrapper
protocol AnyViewModifier {
    func apply(to view: AnyView) -> AnyView
}

struct EnvironmentObjectModifier<T: ObservableObject>: AnyViewModifier {
    let object: T
    func apply(to view: AnyView) -> AnyView {
        AnyView(view.environmentObject(object))
    }
}

// Hauptklasse
final class WindowManager {
    static let shared = WindowManager()
    private var windows: [String: NSWindow] = [:]
    private var delegates: [String: WindowDelegate] = [:]

    // Standard-Open-Methode
    func openWindow<Content: View>(
        id: String = UUID().uuidString,
        title: String,
        width: CGFloat = 800,
        height: CGFloat = 600,
        content: @escaping () -> Content,
        onClose: (() -> Void)? = nil
    ) {
        if let existing = windows[id] {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let controller = NSHostingController(rootView: content())
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        window.title = title
        window.contentViewController = controller
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false
        NSApp.activate(ignoringOtherApps: true)

        let delegate = WindowDelegate(onClose: {
            self.windows.removeValue(forKey: id)
            self.delegates.removeValue(forKey: id)
            onClose?()
        })

        window.delegate = delegate
        delegates[id] = delegate
        windows[id] = window
    }

    // Erweiterung: mit EnvironmentObjects
    func openWithEnvironmentObjects<V: View>(
        _ view: V,
        id: WindowID,
        title: String,
        width: CGFloat = 800,
        height: CGFloat = 600,
        environmentObjects: [AnyViewModifier] = []
    ) {
        var modifiedView: AnyView = AnyView(view)
        for modifier in environmentObjects {
            modifiedView = AnyView(modifier.apply(to: modifiedView))
        }

        self.openWindow(
            id: id.rawValue,
            title: title,
            width: width,
            height: height,
            content: { modifiedView }
        )
    }
}

// WindowDelegate: behält Fenster im Speicher
private class WindowDelegate: NSObject, NSWindowDelegate {
    let onClose: () -> Void
    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }
    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
#endif
*/
