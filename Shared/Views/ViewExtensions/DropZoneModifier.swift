//
//  DropZoneModifier.swift
//  Robart
//
//  Created by Carsten Nichte on 17.04.25.
//

import SwiftUI
import UniformTypeIdentifiers

/// Generischer Drop-Modifier für Transferable-Typen
struct DropZoneModifier<T: Transferable>: ViewModifier {
    let type: UTType
    let onDrop: ([T], CGPoint) -> Bool
    @Binding var isTargeted: Bool

    init(type: UTType, isTargeted: Binding<Bool>, onDrop: @escaping ([T], CGPoint) -> Bool) {
        self.type = type
        self._isTargeted = isTargeted
        self.onDrop = onDrop
    }

    func body(content: Content) -> some View {
        #if os(macOS)
        content
            .dropDestination(for: T.self) { items, location in
                onDrop(items, location)
            } isTargeted: { active in
                isTargeted = active
            }
        #else
        content
            .onDrop(of: [type], isTargeted: $isTargeted) { providers in
                var found = false
                for provider in providers {
                    if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                        found = true
                        _ = provider.loadTransferable(type: T.self) { result in
                            if case .success(let item) = result {
                                DispatchQueue.main.async {
                                    _ = onDrop([item], .zero)
                                }
                            }
                        }
                    }
                }
                return found
            }
        #endif
    }
}
