//
//  AssetStoresDebugToolbar.swift
//  Robart
//
//  Created by Carsten Nichte on 26.04.25.
//

// AssetStoresDebugToolbar.swift
import SwiftUI

struct AssetStoresDebugToolbar: View {
    @EnvironmentObject var assetStores: AssetStores
    @State private var isProcessing = false

    var body: some View {
        VStack(spacing: 10) {
            if isProcessing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }

            Button("🧹 Soft Reset (nur RAM)") {
                Task {
                    await run {
                        assetStores.manager.resetStoresInMemory()
                    }
                }
            }

            Button("🗑️ Hard Reset (Dateien löschen)") {
                Task {
                    await run {
                        await assetStores.manager.resetStoresCompletely(deleteFiles: true)
                    }
                }
            }

            Button("📦 Standarddaten wiederherstellen") {
                Task {
                    await run {
                        await assetStores.manager.restoreDefaultResourcesIfNeeded()
                    }
                }
            }

            Divider()
                .padding(.vertical, 8)

            Button("📝 Zusammenfassung drucken") {
                assetStores.manager.printSummary()
            }
        }
        .padding()
    }

    private func run(_ operation: @escaping () async -> Void) async {
        isProcessing = true
        await operation()
        isProcessing = false
    }
}
