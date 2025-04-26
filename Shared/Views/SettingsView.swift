//
//  SettingsView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 08.04.25.
//

// SettingsStore lädt beim Start asynchron die gespeicherte Datei.
// @Published settings wird in die UI eingebunden.
// Alle Änderungen an settings werden automatisch gespeichert (debounced).
// Du kannst ganz einfach andere Codable-Strukturen benutzen, z. B. AppConfig, UserPreferences, usw.

// "Bitte zwei mal klicken, oder neu starten damit der System-DarkMode aktiviert - bzw. sauber dargetellt - wird!"

// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsStore: GenericStore<SettingsData>
    @EnvironmentObject var assetStores: AssetStores

    init() {
        print("🛠 SettingsView init wurde aufgerufen")
    }

    @AppStorage("currentStorageType")
    private var currentStorageRaw: String = StorageType.local.rawValue

#if DEBUG
    @AppStorage("forceResetOnLaunch") private var resetOnNextLaunch: Bool = false
    @State private var showResetUserDefaultsAlert = false
    @State private var showRollbackMigrationAlert = false
    @State private var showDeleteAllDataAlert = false
    @State private var showSuccessAlert = false
    @State private var successMessage = ""
#endif

    var body: some View {
        Form {
            Section(header: SectionHeader("Allgemein")) {
                Picker("Speicherort", selection: $currentStorageRaw) {
                    Text("Lokal").tag(StorageType.local.rawValue)
                    Text("iCloud").tag(StorageType.iCloud.rawValue)
                }
                .pickerStyle(.segmented)
            }

            Section(header: SectionHeader("Housekeeping")) {
                Button(role: .destructive) {
                    confirmDeleteAllData()
                } label: {
                    Label("Alle Daten löschen", systemImage: "trash")
                }
            }

#if DEBUG
            Section(header: SectionHeader("Developer Tools")) {
                Button {
                    showResetUserDefaultsAlert = true
                } label: {
                    Label("UserDefaults zurücksetzen", systemImage: "arrow.counterclockwise.circle")
                }
                .alert("UserDefaults zurücksetzen?", isPresented: $showResetUserDefaultsAlert) {
                    Button("Zurücksetzen", role: .destructive) {
                        performResetUserDefaults()
                        showSuccess("UserDefaults erfolgreich zurückgesetzt ✅")
                    }
                    Button("Abbrechen", role: .cancel) { }
                }

                Button {
                    showRollbackMigrationAlert = true
                } label: {
                    Label("Migration zurücksetzen", systemImage: "arrow.uturn.backward.circle")
                }
                .alert("Migration zurücksetzen?", isPresented: $showRollbackMigrationAlert) {
                    Button("Zurücksetzen", role: .destructive) {
                        performRollbackMigrations()
                        showSuccess("Migration erfolgreich zurückgesetzt ✅")
                    }
                    Button("Abbrechen", role: .cancel) { }
                }

                Button {
                    FileManagerService.rollbackAllMigrations(storageType: currentStorageType)
                    showSuccess("Alle Migrationen erfolgreich zurückgesetzt ✅")
                } label: {
                    Label("Alle Migrationen zurücksetzen", systemImage: "arrow.uturn.backward.square")
                }

                Button(role: .destructive) {
                    showDeleteAllDataAlert = true
                } label: {
                    Label("Alle gespeicherten Dokumente löschen", systemImage: "trash")
                }
                .alert("Alle Dokumente löschen?", isPresented: $showDeleteAllDataAlert) {
                    Button("Löschen", role: .destructive) {
                        performDeleteAllData()
                        showSuccess("Alle gespeicherten Daten erfolgreich gelöscht ✅")
                    }
                    Button("Abbrechen", role: .cancel) { }
                }

                Toggle(isOn: $resetOnNextLaunch) {
                    Label("Reset beim nächsten Start erzwingen", systemImage: "exclamationmark.triangle")
                }

                AssetStoresDebugToolbar()
                    .environmentObject(assetStores)
            }
#endif
        }
        .navigationTitle("Settings")
        .onChange(of: currentStorageRaw) {
            if let newType = StorageType(rawValue: currentStorageRaw) {
                assetStores.applyInitialStorageTypeAndMigrations(using: newType)
            }
        }
#if DEBUG
        .alert(successMessage, isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) { }
        }
#endif
    }

#if DEBUG

    private func showSuccess(_ message: String) {
        successMessage = message
        showSuccessAlert = true
    }

    private func performResetUserDefaults() {
        print("🔄 Setze UserDefaults zurück...")

        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        for (key, _) in dictionary {
            defaults.removeObject(forKey: key)
        }
    }

    private func performRollbackMigrations() {
        print("🔄 Rolle einmalige Migrationen zurück...")

        FileManagerService.rollbackMigration(resourceName: "papers", storageType: currentStorageType)
        FileManagerService.rollbackMigration(resourceName: "paper-formats", storageType: currentStorageType)
        FileManagerService.rollbackMigration(resourceName: "aspect-ratios", storageType: currentStorageType)
        FileManagerService.rollbackMigration(resourceName: "units", storageType: currentStorageType)
    }

    private func performDeleteAllData() {
        print("🗑️ Lösche alle gespeicherten Dokumente...")
        assetStores.deleteAllData()
        assetStores.resetStoresInMemory()
    }

#endif

    private func confirmDeleteAllData() {
#if os(macOS)
        let alert = NSAlert()
        alert.messageText = "Wirklich alle Daten löschen?"
        alert.informativeText = "Dieser Vorgang kann nicht rückgängig gemacht werden."
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Löschen")
        alert.addButton(withTitle: "Abbrechen")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            performDeleteAllData()
        }
#else
        UIApplication.shared.windows.first?.rootViewController?.present(alertController(), animated: true, completion: nil)
#endif
    }

#if os(iOS)
    private func alertController() -> UIAlertController {
        let alert = UIAlertController(
            title: "Wirklich alle Daten löschen?",
            message: "Dieser Vorgang kann nicht rückgängig gemacht werden.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        alert.addAction(UIAlertAction(title: "Löschen", style: .destructive) { _ in
            performDeleteAllData()
        })
        return alert
    }
#endif

    // MARK: - Hilfsfunktion: Aktuellen StorageType lesen
    private var currentStorageType: StorageType {
        StorageType(rawValue: currentStorageRaw) ?? .local
    }

}
// .toast(message: "Bitte zwei mal klicken, oder neu starten damit der System-DarkMode aktiviert - bzw. sauber dargetellt - wird!", isPresented: $showToast, position: .top, duration: 3, type: .info)
