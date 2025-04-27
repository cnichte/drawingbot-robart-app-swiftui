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
                    AssetManagerHelper.resetAllInMemory(in: assetStores)
                }
            }

            Button("🗑️ Hard Reset (Dateien löschen)") {
                Task {
                       await AssetManagerHelper.deleteAllData(in: assetStores)
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
                AssetManagerHelper.printSummary(of: assetStores)
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
