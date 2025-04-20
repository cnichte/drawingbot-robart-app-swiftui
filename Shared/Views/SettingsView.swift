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
    @EnvironmentObject var settingsStore: GenericStore<SettingsData> // Verwenden des neuen SettingsStore (GenericStore<SettingsData>)

    var body: some View {
        platformNavigationWrapper {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // 👤 Benutzer
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Name")

                        HStack {
                            Image(systemName: "person")
                                .foregroundColor(.accentColor)

                            TextField("Name", text: $settingsStore.items.first?.name ?? .constant("User"))
                                .platformTextFieldModifiers()
                        }
                        .platformVerticalFormSpacing()
                    }

                }
                .padding()
            }
            .navigationTitle("Settings")
            .platformFormPadding()
        }
    }
}

// MARK: - Section Header View

private struct SectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(8)
    }
}


#Preview {
    SettingsView()
}

//             .toast(message: "Bitte zwei mal klicken, oder neu starten damit der System-DarkMode aktiviert - bzw. sauber dargetellt - wird!", isPresented: $showToast, position: .top, duration: 3, type: .info)
