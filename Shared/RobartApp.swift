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

// RobArtApp.swift
import SwiftUI

@main
struct RobartApp: App {
    @StateObject private var projectsStore = GenericStore<ProjectData>(directoryName: "projects")
    @StateObject private var plotJobStore = GenericStore<PlotJobData>(directoryName: "jobs")
    @StateObject private var settingsStore = GenericStore<SettingsData>(directoryName: "settings")
    @StateObject private var pensStore = GenericStore<SettingsData>(directoryName: "pens")
    @StateObject private var connectionsStore = GenericStore<ConnectionData>(directoryName: "connections")
    // @StateObject private var typesStore = GenericStore<TypesData>(directoryName: "types")
    
    init() {
        setupInitialFilesAndDirectories()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(bluetoothManager: BluetoothManager(),  usbScanner:  USBSerialScanner())
                .environmentObject(plotJobStore)
                .environmentObject(settingsStore)
                .environmentObject(projectsStore)
                .environmentObject(pensStore)
                .environmentObject(connectionsStore)
                .preferredColorScheme(.dark) // Setzt die App auf Dark Mode
        }
    }
    
    private func setupInitialFilesAndDirectories() {
        // TODO: plotJobStore, settingsStore, etc initialisieren, bei erststart.
        /*
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Beispiel: Verzeichnis anlegen
        let configDirectory = documentDirectory.appendingPathComponent("Config")
        do {
            try fileManager.createDirectory(at: configDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // Beispiel: Konfigurationsdatei anlegen
            let configFile = configDirectory.appendingPathComponent("settings.json")
            if !fileManager.fileExists(atPath: configFile.path) {
                let defaultConfig = ["key": "value"]
                let jsonData = try JSONSerialization.data(withJSONObject: defaultConfig, options: .prettyPrinted)
                try jsonData.write(to: configFile)
            }
        } catch {
            print("Fehler beim Initialisieren: \(error)")
        }
        */
    }
}
