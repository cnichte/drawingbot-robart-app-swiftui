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

            // Button mit explizitem ButtonStyle und klar definiertem Touch-Bereich
            Button(action: {
                Task {
                    await SVGMigrationTester.performTest()
                }
            }) {
                Text("SVG Migration Test")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle()) // Verhindert unerwünschte Standard-Button-Effekte
            .contentShape(Rectangle()) // Stellt sicher, dass der gesamte Button-Bereich interaktiv ist

            Button(action: {
                Task {
                    await SVGMigrationTester.resetTestSVGs()
                }
            }) {
                Text("SVG Migration Reset")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())

            Divider()

            Button(action: {
                performResetUserDefaults()
                showSuccess("UserDefaults erfolgreich zurückgesetzt ✅")
            }) {
                Text("UserDefaults zurücksetzen")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())

            Button(action: {
                performRollbackMigrations()
                showSuccess("Migration erfolgreich zurückgesetzt ✅")
            }) {
                Text("Migration zurücksetzen")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())

            Button(action: {
                Task {
                    await AssetManagerHelper.deleteAllData(in: assetStores)
                    assetStores.resetAllStoresInMemory()
                    showSuccess("Alle gespeicherten Daten erfolgreich gelöscht ✅")
                }
            }) {
                Text("Alle gespeicherten Daten löschen")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())

            Toggle("Reset beim nächsten Start erzwingen", isOn: $resetOnNextLaunch)
                .padding(.horizontal)

            Divider()

            Button(action: {
                AssetManagerHelper.resetAllInMemory(in: assetStores)
            }) {
                Text("Soft Reset (nur RAM)")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())

            Button(action: {
                Task {
                    await run {
                        await assetStores.manager.restoreDefaultResourcesIfNeeded()
                    }
                }
            }) {
                Text("Standarddaten wiederherstellen")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())

            Divider()

            Button(action: {
                AssetManagerHelper.printSummary(of: assetStores)
            }) {
                Text("📝 Zusammenfassung drucken")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
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
