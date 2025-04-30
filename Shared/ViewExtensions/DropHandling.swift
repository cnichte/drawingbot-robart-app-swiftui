//
//  DropHandling.swift
//  Robart
//
//  Created by Carsten Nichte on 17.04.25.
//

// DropHandling.swift
import SwiftUI
import UniformTypeIdentifiers

extension View {
    func applyCrossPlatformDropHandling(
        isTargeted: Binding<Bool>,
        onDrop: @escaping ([JobData], CGPoint) -> Bool
    ) -> some View {
        #if os(macOS)
        self.dropDestination(for: JobData.self) { items, location in
            onDrop(items, location)
        } isTargeted: { active in
            isTargeted.wrappedValue = active
        }
        #else
        self.onDrop(
            of: [UTType.plotJob],
            isTargeted: isTargeted,
            perform: { providers in
                return handleProviders(providers, onDrop: onDrop)
            }
        )
        #endif
    }
}

private func handleProviders(
    _ providers: [NSItemProvider],
    onDrop: @escaping ([JobData], CGPoint) -> Bool
) -> Bool {
    var found = false

    for provider in providers {
        if provider.hasItemConformingToTypeIdentifier(UTType.plotJob.identifier) {
            found = true

            _ = provider.loadTransferable(type: JobData.self) { (result: Result<JobData, Error>) in
                switch result {
                case .success(let job):
                    DispatchQueue.main.async {
                        _ = onDrop([job], .zero)
                    }
                case .failure(let error):
                    appLog(.info, "Fehler beim Laden von JobData: \(error)")
                }
            }
        }
    }

    return found
}
