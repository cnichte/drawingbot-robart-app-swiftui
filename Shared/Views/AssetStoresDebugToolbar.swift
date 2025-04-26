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
    @State private var selectedStoreKey: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            
            // 🛠 Dropdown-Menü für Einzel-Reset
            Picker("Store auswählen", selection: $selectedStoreKey) {
                ForEach(assetStores.storeList.map { $0.key }, id: \.self) { key in
                    Text(key).tag(key)
                }
            }
            .pickerStyle(.menu)
            .padding(.bottom, 8)
            
            HStack {
                Button("🔁 Nur RAM neu laden") {
                    if let store = assetStores.storeList.first(where: { $0.key == selectedStoreKey })?.store {
                        assetStores.resetStoreCompletely(store, deleteFiles: false)
                    }
                }
                
                Button("🗑️ Dateien löschen + neu laden") {
                    if let store = assetStores.storeList.first(where: { $0.key == selectedStoreKey })?.store {
                        assetStores.resetStoreCompletely(store, deleteFiles: true)
                    }
                }
            }
            
            Divider()
            
            // 🛠 Buttons für alle Stores
            Button("🧹 Soft Reset (nur RAM)") {
                assetStores.resetStoresInMemory()
            }
            
            Button("🗑️ Hard Reset (löschen + neu laden)") {
                assetStores.resetStoresCompletely(deleteFiles: true)
            }
            
            Button("📦 Standarddaten wiederherstellen") {
                assetStores.restoreDefaultResources()
            }
            
            Button("📝 Zusammenfassung drucken") {
                assetStores.printSummary()
            }
        }
        .padding()
        .onAppear {
            if selectedStoreKey.isEmpty, let firstKey = assetStores.storeList.first?.key {
                selectedStoreKey = firstKey
            }
        }
    }
}
