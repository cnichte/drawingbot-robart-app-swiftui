//
//  PlatformSidebarAndInspectorToolbar.swift
//  Robart
//
//  Created by Carsten Nichte on 05.05.25.
//

import SwiftUI

struct PlatformSidebarAndInspectorToolbar: ViewModifier {
    let toggleSidebar: () -> Void
    let toggleInspector: () -> Void
    
    func body(content: Content) -> some View {
        content
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button(action: toggleInspector) {
                        Image(systemName: "sidebar.trailing")
                    }
                }
#else
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.leading")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: toggleInspector) {
                        Image(systemName: "sidebar.trailing")
                    }
                }
#endif
            }
    }
}

extension View {
    /// Fügt auf macOS und iOS eine Toolbar mit Sidebar- und Inspector-Toggle hinzu
    func platformSidebarAndInspectorToolbar(
        toggleSidebar: @escaping () -> Void,
        toggleInspector: @escaping () -> Void
    ) -> some View {
        self.modifier(PlatformSidebarAndInspectorToolbar(
            toggleSidebar: toggleSidebar,
            toggleInspector: toggleInspector
        ))
    }
}
