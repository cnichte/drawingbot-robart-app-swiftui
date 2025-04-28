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
    @AppStorage("forceResetOnLaunch") private var resetOnNextLaunch: Bool = false
    @State private var isProcessing = false
    @State private var showSuccessAlert = false
    @State private var successMessage = ""

    var body: some View {
        VStack(spacing: 12) {
            if isProcessing {
                ProgressView()
                    .progressViewStyle(.circular)
            }

            Button("🔎 SVG Migration Test") {
                Task {
                    await SVGMigrationTester.performTest()
                }
            }
            
            Button("🧹 SVG Migration Reset") {
                Task {
                    await SVGMigrationTester.resetTestSVGs()
                }
            }
            
            Divider()
            
            Button("🔄 UserDefaults zurücksetzen") {
                performResetUserDefaults()
                showSuccess("UserDefaults erfolgreich zurückgesetzt ✅")
            }

            Button("↩️ Migration zurücksetzen") {
                performRollbackMigrations()
                showSuccess("Migration erfolgreich zurückgesetzt ✅")
            }

            Button("🗑️ Alle gespeicherten Daten löschen") {
                Task {
                    await AssetManagerHelper.deleteAllData(in: assetStores)
                    assetStores.resetAllStoresInMemory()
                    showSuccess("Alle gespeicherten Daten erfolgreich gelöscht ✅")
                }
            }

            Toggle("Reset beim nächsten Start erzwingen", isOn: $resetOnNextLaunch)

            Divider()

            Button("🧹 Soft Reset (nur RAM)") {
                AssetManagerHelper.resetAllInMemory(in: assetStores)
            }

            Button("📦 Standarddaten wiederherstellen") {
                Task {
                    await run {
                        await assetStores.manager.restoreDefaultResourcesIfNeeded()
                    }
                }
            }

            Divider()

            Button("📝 Zusammenfassung drucken") {
                AssetManagerHelper.printSummary(of: assetStores)
            }
        }
        .padding()
        .alert(successMessage, isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private func run(_ operation: @escaping () async -> Void) async {
        isProcessing = true
        await operation()
        isProcessing = false
    }

    private func showSuccess(_ message: String) {
        successMessage = message
        showSuccessAlert = true
    }

    private func performResetUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.dictionaryRepresentation().keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }

    private func performRollbackMigrations() {
        FileManagerService.shared.rollbackUserResource(for: "papers", storageType: currentStorageType)
        FileManagerService.shared.rollbackUserResource(for: "paper-formats", storageType: currentStorageType)
        FileManagerService.shared.rollbackUserResource(for: "aspect-ratios", storageType: currentStorageType)
        FileManagerService.shared.rollbackUserResource(for: "units", storageType: currentStorageType)
    }

    private var currentStorageType: StorageType {
        StorageType(rawValue: UserDefaults.standard.string(forKey: "currentStorageType") ?? StorageType.local.rawValue) ?? .local
    }
}
