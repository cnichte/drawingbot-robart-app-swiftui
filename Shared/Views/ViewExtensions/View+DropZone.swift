//
//  View+DropZone.swift
//  Robart
//
//  Created by Carsten Nichte on 17.04.25.
//
// View+DropZone.swift
// Plattformübergreifender Drop-Zonen-Modifier mit generischem Transferable-Typ
// Modifier, der eine Drop-Zone für Transferable-Typen bietet (macOS & iOS)

// View+DropZone.swift
import SwiftUI
import UniformTypeIdentifiers

extension View {
    /// Plattformübergreifender Drop-Modifier für beliebige Transferable-Typen
    func dropZone<T: Transferable>(
        of type: UTType,
        isTargeted: Binding<Bool>,
        onDrop: @escaping ([T], CGPoint) -> Bool
    ) -> some View {
        #if os(macOS)
        return self.dropDestination(for: T.self) { items, location in
            onDrop(items, location)
        } isTargeted: { active in
            isTargeted.wrappedValue = active
        }
        #else
        return self.onDrop(of: [type], isTargeted: isTargeted) { providers in
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

extension View {
    /// Drop-Zone für einen beliebigen Transferable-Typ
    func dropZone<T: Transferable>(
        type: UTType,
        isTargeted: Binding<Bool>,
        onDrop: @escaping ([T], CGPoint) -> Bool
    ) -> some View {
        self.modifier(DropZoneModifier(type: type, isTargeted: isTargeted, onDrop: onDrop))
    }
}
