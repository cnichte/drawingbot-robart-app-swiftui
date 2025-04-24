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
    @AppStorage("currentStorageType")
    private var currentStorageRaw: String = StorageType.local.rawValue

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Form {
                Section(header: SectionHeader("Allgemein")) {
                    Picker("Speicherort", selection: $currentStorageRaw) {
                        Text("Lokal").tag(StorageType.local.rawValue)
                        Text("iCloud").tag(StorageType.iCloud.rawValue)
                    }
                    .pickerStyle(.segmented)
                }

                // Weitere Sektionen oder Einstellungen können hier ergänzt werden
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Einstellungen")
    }
}


// .toast(message: "Bitte zwei mal klicken, oder neu starten damit der System-DarkMode aktiviert - bzw. sauber dargetellt - wird!", isPresented: $showToast, position: .top, duration: 3, type: .info)
