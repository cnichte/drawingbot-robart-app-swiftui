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

    var body: some View {
        VStack(spacing: 10) {
            Button("🧹 Soft Reset (nur RAM)") {
                assetStores.resetStoresInMemory()
            }
            
            Button("🗑️ Hard Reset (löschen + neu laden)") {
                Task {
                    assetStores.resetStoresCompletely(deleteFiles: true)
                }
            }
            
            Divider()
            
            Button("📦 Standarddaten wiederherstellen") {
                Task {
                    await assetStores.restoreDefaultResourcesIfNeeded()
                }
            }
            
            Divider()
            
            Button("📝 Zusammenfassung drucken") {
                assetStores.printSummary()
            }
        }
        .padding()
    }
}
