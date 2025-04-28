//
//  DeviceListView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 08.04.25.
//

// DeviceListView.swift
import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    #if os(macOS)
    @StateObject private var scanner = USBSerialScanner()
    #endif

    var body: some View {
        ScrollView {
            CollapsibleSection(
                title: "Bluetooth Devices",
                systemImage: "wave.3.up",
                toolbar: {
                    HStack(spacing: 8) {
                        Button("Scan RobArt") {
                            startBluetoothScan(filter: true)
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Alle Geräte") {
                            startBluetoothScan(filter: false)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            ) {
                bluetoothSectionContent()
            }

            #if os(macOS)
            // Nur macOS: USB Devices Section
            CollapsibleSection(
                title: "USB Devices",
                systemImage: "externaldrive",
                toolbar: {
                    HStack(spacing: 8) {
                        Button("Scan USB") {
                            startUSBScan()
                        }
                        Button("Verbinden") {
                            scanner.connectToSelectedDevice()
                        }
                        .disabled(scanner.selectedDevice == nil)
                    }
                }
            ) {
                usbSectionContent()
            }
            #endif
        }
        .navigationTitle("Geräte verbinden")
        .padding()
    }

    // MARK: - Bluetooth Section
    @ViewBuilder
    private func bluetoothSectionContent() -> some View {
        // Dein Bluetooth-Code hier
    }

    #if os(macOS)
    // MARK: - USB Section
    @ViewBuilder
    private func usbSectionContent() -> some View {
        // Dein USB-Code hier
    }
    #endif

    private func startBluetoothScan(filter: Bool) {
        bluetoothManager.startScan(filter: filter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            AutoConnectService.shared.tryAutoConnectBluetooth(bluetoothManager: bluetoothManager)
        }
    }

    #if os(macOS)
    private func startUSBScan() {
        scanner.scanSerialDevices()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            AutoConnectService.shared.tryAutoConnectUSB(usbScanner: scanner)
        }
    }
    #endif
}
