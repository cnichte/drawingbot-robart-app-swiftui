//
//  DeviceListView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 08.04.25.
//

// DeviceListView.swift
import SwiftUI

struct DeviceListView: View {
    @ObservedObject var bluetoothManager: BluetoothManager

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
            CollapsibleSection(
                title: "USB Devices",
                systemImage: "externaldrive",
                toolbar: {
                    HStack(spacing: 8) {
                        Button("Scan USB") {
                            scanner.scanSerialDevices()
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
        VStack(alignment: .leading, spacing: 16) {
            if bluetoothManager.isScanning {
                HStack {
                    ProgressView()
                    Text("Suche nach Geräten...")
                }
            }
            if let last = bluetoothManager.lastScanDate {
                Text("Letzter Scan: \(last.formatted(.dateTime.hour().minute().second()))")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            ForEach(bluetoothManager.peripherals) { discovered in
                deviceCard(for: discovered)
            }
        }
    }

    @ViewBuilder
    private func deviceCard(for discovered: DiscoveredPeripheral) -> some View {
        let isConnected = bluetoothManager.connectedPeripheralID == discovered.peripheral.identifier

        HStack(alignment: .top) {
            deviceInfoView(for: discovered, isConnected: isConnected)
            Spacer()
            deviceActionsView(for: discovered, isConnected: isConnected)
        }
        .padding(8)
        .background(isConnected ? Color.green.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2))
        )
    }

    private func deviceInfoView(for discovered: DiscoveredPeripheral, isConnected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(discovered.peripheral.name ?? "Unbekannt")
                .font(.headline)
            Text("RSSI: \(discovered.rssi)")
                .font(.caption)
                .foregroundColor(.gray)

            if isConnected {
                Text("✅ Verbunden")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }

    private func deviceActionsView(for discovered: DiscoveredPeripheral, isConnected: Bool) -> some View {
        VStack(spacing: 6) {
            if isConnected {
                Button {
                    bluetoothManager.disconnect()
                } label: {
                    Label("Trennen", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .help("Bluetooth-Verbindung trennen")
            } else {
                Button {
                    bluetoothManager.connect(to: discovered.peripheral)
                } label: {
                    Label("Verbinden", systemImage: "link.circle")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

#if os(macOS)
    // MARK: - USB Section

    @ViewBuilder
    private func usbSectionContent() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            List(selection: $scanner.selectedDevice) {
                ForEach(scanner.devices) { device in
                    VStack(alignment: .leading) {
                        Text(device.name)
                        if let vendor = device.vendorID, let product = device.productID {
                            Text("Vendor ID: \(vendor), Product ID: \(product)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(height: 250)

            if let selected = scanner.selectedDevice {
                Text("Ausgewählt: \(selected.path)")
                    .foregroundColor(.blue)
            }
        }
    }
#endif

    // MARK: - Start Scan

    private func startBluetoothScan(filter: Bool) {
        bluetoothManager.startScan(filter: filter)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            AutoConnectService.shared.tryAutoConnectBluetooth(bluetoothManager: bluetoothManager)
        }
    }
}

// MARK: - Preview

struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView(bluetoothManager: MockBluetoothManager())
    }
}
