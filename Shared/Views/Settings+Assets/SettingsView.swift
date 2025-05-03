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

// Man kann entweder plotten, oder wie eine Fernsteuerung benutzen.
enum ControlType: String, Codable {
    case plotterControl = ".potterControl"
    case remoteControl = ".remoteControl"
}

struct SettingsView: View {
    @EnvironmentObject var settingsStore: GenericStore<SettingsData>
    @EnvironmentObject var assetStores: AssetStores

    @AppStorage("currentStorageType") private var currentStorageRaw: String = StorageType.local.rawValue
    @AppStorage("currentControlType") private var currentControlType: String = ControlType.plotterControl.rawValue
    
    @AppStorage("loggingEnabled") private var loggingEnabled: Bool = true
    @AppStorage("logLevel") private var logLevel: LogLevel = .verbose

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                CollapsibleSection(title: "Allgemein", systemImage: "gear") {
                    Picker("Speicherort", selection: $currentStorageRaw) {
                        Text("Lokal").tag(StorageType.local.rawValue)
                        Text("iCloud").tag(StorageType.iCloud.rawValue)
                    }
                    .pickerStyle(.segmented)
                }

                CollapsibleSection(title: "Fernsteuerung", systemImage: "gamecontroller") {
                    Picker("ControlType", selection: $currentControlType) {
                        Text("potterControl").tag(ControlType.plotterControl.rawValue)
                        Text("remoteControl").tag(ControlType.remoteControl.rawValue)
                    }
                    .pickerStyle(.segmented)
                    Text("Du kannst die App im Plotter-Modus verwenden, oder die Fernsteuerung nutzen.")
                }
                
                
                CollapsibleSection(title: "Logging", systemImage: "doc.text.magnifyingglass") {
                    Toggle(isOn: $loggingEnabled) {
                        Label("Logging aktivieren", systemImage: "doc.text.magnifyingglass")
                    }
                    Picker("Log-Level", selection: $logLevel) {
                        ForEach(LogLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                CollapsibleSection(title: "Housekeeping", systemImage: "trash") {
                    Button(role: .destructive) {
                        confirmDeleteAllData()
                    } label: {
                        Label("Alle Daten löschen", systemImage: "trash")
                    }
                }

                #if DEBUG
                CollapsibleSection(title: "Developer Tools", systemImage: "hammer") {
                    AssetStoresDebugToolbar()
                        .environmentObject(assetStores)
                }
                #endif
            }
            .padding(.vertical)
            .frame(maxWidth: 700)
            .padding(.horizontal)
        }
        .navigationTitle("Settings")
        .onChange(of: currentStorageRaw) {
            if let newType = StorageType(rawValue: currentStorageRaw) {
                assetStores.applyInitialStorageTypeAndMigrations(using: newType)
            }
        }
    }

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
            // Hard reset wird vom DebugToolbar angeboten, keine Aktion hier
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
            // Hard reset wird vom DebugToolbar angeboten, keine Aktion hier
        })
        return alert
    }
    #endif
}
// .toast(message: "Bitte zwei mal klicken, oder neu starten damit der System-DarkMode aktiviert - bzw. sauber dargetellt - wird!", isPresented: $showToast, position: .top, duration: 3, type: .info)
