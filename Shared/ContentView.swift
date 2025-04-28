//
//  ContentView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 06.04.25.
//  Copyright (C) 2025
//  https://carsten-nichte.de/docs/drawingbot/
//  This file is part of Robart.
//  Licensed under the GNU General Public License v3.0. See LICENSE for details.
//

// ContentView.swift
import SwiftUI

struct ContentView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
#if os(macOS)
    @ObservedObject var usbScanner: USBSerialScanner
#endif
    @EnvironmentObject var assetStores: AssetStores
    
    @State private var selectedTab = 0
    
    init(bluetoothManager: BluetoothManager, usbScanner: USBSerialScanner) {
        self.bluetoothManager = bluetoothManager
#if os(macOS)
        self.usbScanner = usbScanner
#endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ConnectionStatusHeader(bluetoothManager: bluetoothManager)
                .environmentObject(assetStores)
#if os(macOS)
                .environmentObject(usbScanner)
#endif
            
            TabView(selection: $selectedTab) {
                DeviceListView(bluetoothManager: bluetoothManager)
                    .tag(0)
                    .tabItem {
                        Label("Verbindung", systemImage: "dot.radiowaves.left.and.right")
                    }
                
                RemoteControlView(bluetoothManager: bluetoothManager)
                    .tag(1)
                    .tabItem {
                        Label("Fernsteuerung", systemImage: "gamecontroller")
                    }
                
                JobListView() // << Direkter Aufruf!
                    .tag(2)
                    .tabItem {
                        Label("Plotter Jobs", systemImage: "printer")
                    }
                
                AssetsAndSettingsView()
                    .tag(3)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                
                AboutMeView()
                    .tag(4)
                    .tabItem {
                        Label("Über mich", systemImage: "person.circle")
                    }
            }
        }
    }
}

// Vorschau mit Dummy-Daten
class MockBluetoothManager: BluetoothManager {
    override init() {
        super.init()
        self.isConnected = true
        self.receivedMessage = "Demo-Modus aktiv"
        self.peripherals = []
    }
}

/*
 struct ContentView_Previews: PreviewProvider {
 static var previews: some View {
 ContentView(bluetoothManager: MockBluetoothManager())
 }
 }
 */


/*
 
 
 */
