//
//  RobartApp.swift
//  Robart
//
//  Created by Carsten Nichte on 15.04.25.
//  Copyright (C) 2025
//  https://carsten-nichte.de/docs/drawingbot/
//  This file is part of Robart.
//  Licensed under the GNU General Public License v3.0. See LICENSE for details.
//

// RobArtApp.swift (zentrale Stelle für EnvironmentObject-Setup)
import SwiftUI

@main
struct RobartApp: App {
    
    @StateObject private var settingsStore = GenericStore<SettingsData>(directoryName: "settings")
    @StateObject private var assetStores = AssetStores(initialStorageType: .local)
    
    @StateObject private var bluetoothManager = BluetoothManager()  // Hinzugefügt
    @StateObject private var usbScanner = USBSerialScanner() // Hinzugefügt
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(assetStores)  // EnvironmentObject für AssetStores
                .environmentObject(settingsStore) // EnvironmentObject für SettingsStore
                .environmentObject(bluetoothManager) // EnvironmentObject für BluetoothManager
                .environmentObject(usbScanner) // EnvironmentObject für USBScanner
                
                .environmentObject(assetStores.connectionsStore)
                .environmentObject(assetStores.machineStore)
                .environmentObject(assetStores.projectStore)
                .environmentObject(assetStores.plotJobStore)
                .environmentObject(assetStores.pensStore)
                .environmentObject(assetStores.paperStore)
                .environmentObject(assetStores.paperFormatsStore)
                
                .preferredColorScheme(.dark)
                .onAppear {
                    if CommandLine.arguments.contains("-ResetApp") {
                        AppResetHelper.fullResetAll()
                    }
                    if UserDefaults.standard.bool(forKey: "forceResetOnLaunch") {
                        appLog(.info, "🚨 Starte mit vollständigem Reset...")
                        UserDefaults.standard.set(false, forKey: "forceResetOnLaunch")
                        
                        Task {
                            await assetStores.deleteAllLocalData()
                            assetStores.resetAllStoresInMemory()
                        }
                        
                    }
                    Task {
                        // Stelle sicher, dass ein Settings-Datensatz vorhanden ist
                        if settingsStore.items.isEmpty {
                            let defaultSettings = SettingsData()
                            await settingsStore.save(item: defaultSettings, fileName: defaultSettings.id.uuidString)
                        }
                        
                        // Wende bevorzugten Speicherort an und führe ggf. Migration durch
                        if let preferred = settingsStore.items.first?.preferredStorage {
                            assetStores.applyInitialStorageTypeAndMigrations(using: preferred)
                        }
                    }
                }
        }
    }
}

/*
 init() {
 // setupInitialFilesAndDirectories()
 }
 
 func applicationDidLaunch() {
 // setupInitialFilesAndDirectories()
 }
 */
