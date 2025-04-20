//
//  WindowManager+Extensions.swift
//  Robart
//
//  Created by Carsten Nichte on 17.04.25.
//

// ✅ openWindow mit @ViewBuilder und optionalem onClose
// ✅ Unterstützung für WindowID zur typsicheren Verwendung
// ✅ Helfer für .sheet- und .popover-ähnliche Fenster

/* Beispiele:
 
 1. Fenster mit EnvironmentObjects öffnen
 
 WindowManager.shared.openWithEnvironmentObjects(
     ProjectEditorView(),
     id: .projectEditor,
     title: "Projekte verwalten",
     width: 900,
     height: 600,
     environmentObjects: [
         EnvironmentObjectModifier(object: projectStore),
         EnvironmentObjectModifier(object: jobStore)
     ]
 )
 
 2. Sheet anzeigen mit beliebiger View
 
 WindowManager.shared.openSheet(
     JobDetailView(job: selectedJob),
     title: "Job-Details",
     width: 500,
     height: 300
 )
 
 
 3. Popover-Fenster (z. B. für Hilfe oder Mini-Konfiguration)
 
 WindowManager.shared.openPopover(
     Text("Dies ist ein Popover"),
     title: "Info",
     width: 300,
     height: 150
 )
 
4. Kombinierbar mit .environmentObject(...) direkt, falls du keine Liste brauchst:
 
 WindowManager.shared.openSheet(
     ProjectEditorView()
         .environmentObject(projectStore)
         .environmentObject(jobStore),
     title: "Projekte",
     width: 800,
     height: 600
 )
 */


// WindowManager+Extensions.swift
#if os(macOS)
import SwiftUI
import AppKit

// MARK: - EnvironmentObject Unterstützung für AnyView
protocol AnyViewModifier {
    func apply(to view: AnyView) -> AnyView
}

struct EnvironmentObjectModifier<T: ObservableObject>: AnyViewModifier {
    let object: T

    func apply(to view: AnyView) -> AnyView {
        AnyView(view.environmentObject(object))
    }
}

// MARK: - WindowManager-Erweiterung
extension WindowManager {

    /// Öffnet ein neues Fenster mit EnvironmentObjects
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
    
    func openTabbedWindow(
            id: WindowID,
            title: String,
            width: CGFloat = 900,
            height: CGFloat = 600,
            views: [(label: String, view: AnyView)]
        ) {
            let tabView = TabView {
                ForEach(0..<views.count, id: \.self) { index in
                    views[index].view
                        .tabItem { Text(views[index].label) }
                }
            }

            openWindow(
                id: id.rawValue,
                title: title,
                width: width,
                height: height,
                content: { tabView }
            )
        }

    /// Öffnet ein modales Sheet-Fenster
    func openSheet<V: View>(
        _ view: V,
        title: String,
        width: CGFloat = 400,
        height: CGFloat = 300
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = title
        window.contentViewController = NSHostingController(rootView: view)
        window.center()
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = true
        window.level = .modalPanel
        NSApp.runModal(for: window)
    }

    /// Öffnet ein Popover-artiges Hilfsfenster
    func openPopover<V: View>(
        _ view: V,
        width: CGFloat = 300,
        height: CGFloat = 200
    ) {
        let popoverWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        popoverWindow.title = ""
        popoverWindow.contentViewController = NSHostingController(rootView: view)
        popoverWindow.center()
        popoverWindow.makeKeyAndOrderFront(nil)
        popoverWindow.isReleasedWhenClosed = true
        popoverWindow.level = .floating
    }
}

// MARK: - WindowManager Singleton
final class WindowManager {
    static let shared = WindowManager()
    private var windows: [String: NSWindow] = [:]
    private var delegates: [String: WindowDelegate] = [:]

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
}

// MARK: - WindowDelegate intern
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
