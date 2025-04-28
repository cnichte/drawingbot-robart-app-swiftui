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
import CoreBluetooth

struct ContentView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager // EnvironmentObject statt ObservedObject
    @EnvironmentObject var usbScanner: USBSerialScanner // EnvironmentObject statt ObservedObject
    @EnvironmentObject var assetStores: AssetStores
    
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            ConnectionStatusHeader()
                .environmentObject(assetStores)
            
#if os(macOS)
            .environmentObject(usbScanner)
#endif

            TabView(selection: $selectedTab) {
                DeviceListView() // Verwendet das EnvironmentObject für BluetoothManager
                    .tag(0)
                    .tabItem {
                        Label("Verbindung", systemImage: "dot.radiowaves.left.and.right")
                    }
                
                RemoteControlView()
                    .tag(1)
                    .tabItem {
                        Label("Fernsteuerung", systemImage: "gamecontroller")
                    }
                
                JobListView() // Direkter Aufruf
                    .tag(2)
                    .tabItem {
                        Label("Plotter Jobs", systemImage: "printer")
                    }
                
                AssetsAndSettingsView() // Weiterhin verwendet
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
