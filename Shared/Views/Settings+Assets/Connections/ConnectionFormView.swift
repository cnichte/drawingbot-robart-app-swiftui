//
//  ConnectionFormView.swift
//  Robart
//
//  Created by Carsten Nichte on 23.04.25.
//

import SwiftUI

struct ConnectionFormView: View {
    @Binding var data: ConnectionData
    @EnvironmentObject var store: GenericStore<ConnectionData>
    @EnvironmentObject var bluetoothManager: BluetoothManager

    #if os(macOS) // Hier aktivieren wir den USB-Scanner nur für macOS
    @EnvironmentObject var scanner: USBSerialScanner
    #endif

    @State private var selectedBluetoothPeripheral: DiscoveredPeripheral?
    @State private var selectedUSBDevice: USBSerialDevice?
    @State private var isScanningBluetooth: Bool = false // Flag für Bluetooth-Scanning
    @State private var isScanningUSB: Bool = false // Flag für USB-Scanning

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $data.name)
                    .platformTextFieldModifiers()
                    .onChange(of: data.name) { save() }

                TextEditor(text: $data.description)
                    .frame(minHeight: 100)
                    .onChange(of: data.description) { save() }
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.2))
                    )
            } header: {
                Text("Details")
            }

            Section(header: Text("Gerät auswählen")) {
                // Bluetooth Geräte
                if isScanningBluetooth {
                    ProgressView("Suche nach Bluetooth-Geräten...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Picker("Bluetooth", selection: $selectedBluetoothPeripheral) {
                        Text("Kein Gerät auswählen").tag(nil as DiscoveredPeripheral?)
                        ForEach(bluetoothManager.peripherals) { peripheral in
                            Text(peripheral.peripheral.name ?? "Unbekannt").tag(peripheral as DiscoveredPeripheral?)
                        }
                    }
                    .onAppear {
                        if bluetoothManager.peripherals.isEmpty {
                            startBluetoothScan()
                        }
                    }
                }

                #if os(macOS)
                // USB Geräte nur für macOS
                if isScanningUSB {
                    ProgressView("Suche nach USB-Geräten...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Picker("USB", selection: $selectedUSBDevice) {
                        Text("Kein Gerät auswählen").tag(nil as USBSerialDevice?)
                        ForEach(scanner.devices) { device in
                            Text(device.name).tag(device as USBSerialDevice?)
                        }
                    }
                    .onAppear {
                        if scanner.devices.isEmpty {
                            startUSBScan()
                        }
                    }
                }
                #endif
            }

            // Button um die Zuordnung vorzunehmen
            Button("Speichern und verbinden") {
                if let bluetoothPeripheral = selectedBluetoothPeripheral {
                    // Bluetooth Verbindung herstellen
                    bluetoothManager.connect(to: bluetoothPeripheral.peripheral)
                } else if let usbDevice = selectedUSBDevice {
                    #if os(macOS)
                    // USB Verbindung nur auf macOS
                    scanner.connect(to: usbDevice)
                    #endif
                }
                save()
            }
        }
        .platformFormPadding()
        .navigationTitle("Verbindung erstellen")
        .onReceive(store.$refreshTrigger) { _ in
            // Re-render wird automatisch ausgelöst
        }
    }

    private func save() {
        Task {
            await store.save(item: data, fileName: data.id.uuidString)
        }
    }

    // Bluetooth Scannen starten
    private func startBluetoothScan() {
        isScanningBluetooth = true
        bluetoothManager.startScan(filter: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isScanningBluetooth = false
        }
    }

    // USB Scannen starten
    private func startUSBScan() {
        isScanningUSB = true
        #if os(macOS)
        scanner.scanSerialDevices()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isScanningUSB = false
        }
        #endif
    }
}
