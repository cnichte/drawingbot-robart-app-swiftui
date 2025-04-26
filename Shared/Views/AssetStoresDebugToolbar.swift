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
        VStack(spacing: 8) {
            Text("🛠️ AssetStores Debug Toolbar")
                .font(.headline)
                .padding(.bottom, 4)

            HStack(spacing: 12) {
                Button("🧹 Soft Reset") {
                    assetStores.resetStoresCompletely(deleteFiles: false)
                }
                .buttonStyle(.bordered)

                Button("🗑️ Hard Reset") {
                    assetStores.resetStoresCompletely(deleteFiles: true)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            
            Button("♻️ restore Standarddaten") {
                assetStores.restoreDefaultResources()
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)

            Button("📝 Übersicht drucken") {
                assetStores.printSummary()
            }
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding()
    }
}
