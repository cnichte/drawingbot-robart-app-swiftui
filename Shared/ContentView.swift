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
    @State private var selectedTab = 0
    @State private var selectedJob: PlotJobData
    @State private var currentStep: Int = 1

    init(bluetoothManager: BluetoothManager, usbScanner: USBSerialScanner) {
        self.bluetoothManager = bluetoothManager
#if os(macOS)
        self.usbScanner = usbScanner
#endif
        self._selectedJob = State(initialValue: PlotJobData(
            id: UUID(),
            name: "Neuer Job",
            description: "",
            paperSize: PaperSize(name: "A4", width: 210, height: 297, orientation: 0, note: ""),
            svgFilePath: "",
            pitch: 0.0,
            zoom: 1.0,
            origin: CGPoint(x: 0, y: 0)
        ))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header mit Verbindungsstatus und Disconnect-Button für Bluetooth und USB
            HStack(spacing: 12) {
                // Bluetooth-Status
                HStack(spacing: 6) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.green)
                    if bluetoothManager.isConnected {
                        Text("Bluetooth verbunden")
                            .foregroundColor(.green)
                            .help("Verbunden mit \(bluetoothManager.connectedPeripheralName)")
                            .lineLimit(1)
                            .fixedSize()
                            .layoutPriority(1)
                        Button {
                            bluetoothManager.disconnect()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Bluetooth-Verbindung trennen")
                    } else {
                        Text("Bluetooth getrennt")
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }

                Divider()
                    .frame(height: 20)

                // USB-Status
                #if os(macOS)
                HStack(spacing: 6) {
                    Image(systemName: "externaldrive.connected.to.line.below")
                        .foregroundColor(.blue)
                    if let usbPort = usbScanner.currentPort, usbPort.isOpen {
                        Text("USB verbunden")
                            .foregroundColor(.blue)
                            .help("Verbunden mit \(usbPort.name)")
                            .lineLimit(1)
                            .fixedSize()
                            .layoutPriority(1)
                        Button {
                            usbPort.close()
                            usbScanner.currentPort = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("USB-Verbindung trennen")
                    } else {
                        Text("USB getrennt")
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .fixedSize()
                    }
                }
                #else
                Text("USB nicht unterstützt")
                    .foregroundColor(.gray)
                    .help("USB-Verbindungen sind auf iOS nicht verfügbar")
                    .lineLimit(1)
                    .fixedSize()
                #endif

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(ColorHelper.backgroundColor)
            .font(.footnote)
            .frame(minHeight: 28, maxHeight: 32)
            // Header Ende
            
            // TabBar, TabView für verschiedene Ansichten
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

                PlotterWizardView(goToStep: $currentStep, selectedJob: $selectedJob)
                    .tag(2)
                    .tabItem {
                        Label("Plotter", systemImage: "printer")
                    }
                
                AssetsAndSettingsView()
                    .tag(3)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                /*
                AssetsView()
                    .tag(3)
                    .tabItem {
                        Label("Assets", systemImage: "gear")
                    }

                AboutMeView()
                    .tag(4)
                    .tabItem {
                        Label("Über mich", systemImage: "person.circle")
                    }
                */
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
