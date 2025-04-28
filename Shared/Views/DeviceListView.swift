//
//  DeviceListView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 08.04.25.
//

// DeviceListView.swift
import SwiftUI

#if os(macOS)
import ORSSerial

extension ORSSerialPort: @retroactive Identifiable {
    public var id: String {
        self.name
    }
}
#endif

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
                            bluetoothManager.startScan(filter: true)
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Alle Geräte") {
                            bluetoothManager.startScan(filter: false)
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

    // MARK: - USB Section
    @ViewBuilder
    private func usbSectionContent() -> some View {
#if os(macOS)
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
#else
        Text("USB-Serial nicht unterstützt.")
            .foregroundColor(.gray)
            .padding()
#endif
    }

    // MARK: - Device Card
    @ViewBuilder
    private func deviceCard(for discovered: DiscoveredPeripheral) -> some View {
        let isConnected = bluetoothManager.connectedPeripheralID == discovered.peripheral.identifier
        let isFavorite = bluetoothManager.favoriteUUID == discovered.peripheral.identifier

        HStack(alignment: .top) {
            VStack(alignment: .leading) {
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

            Spacer()

            VStack(spacing: 6) {
                if isConnected {
                    Button {
                        bluetoothManager.disconnect()
                    } label: {
                        Label("Trennen", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                } else {
                    Button {
                        bluetoothManager.connect(to: discovered.peripheral)
                    } label: {
                        Label("Verbinden", systemImage: "link.circle")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    bluetoothManager.favoriteUUID = isFavorite ? nil : discovered.peripheral.identifier
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
                .buttonStyle(.plain)
            }
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
}

// MARK: - Preview

struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView(bluetoothManager: MockBluetoothManager())
    }
}

/*
 struct DeviceListView: View {
 @ObservedObject var bluetoothManager: BluetoothManager
 
 var body: some View {
 VStack(spacing: 10) {
 HStack(spacing: 10) {
 Button("🔍 Bluetooth: Scan nach RobArt (HM-10)") {
 bluetoothManager.startScan(filter: true)
 }
 .buttonStyle(.borderedProminent)
 
 Button("🔎 Bluetooth: Scan Alle") {
 bluetoothManager.startScan(filter: false)
 }
 .buttonStyle(.bordered)
 
 Button("🔍 Scan nach USB Devices") {
 // TODO: USB Support
 }
 .buttonStyle(.borderedProminent)
 }
 
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
 
 GeometryReader { geometry in
 VStack(spacing: 10) {
 
 // Bluetooth Devices (50%)
 VStack(alignment: .leading, spacing: 0) {
 Text("Bluetooth Devices")
 .font(.headline)
 .foregroundColor(.white)
 .padding()
 .frame(maxWidth: .infinity)
 .background(Color.gray.opacity(0.8))
 
 ScrollView {
 VStack(alignment: .leading) {
 ForEach(bluetoothManager.peripherals) { discovered in
 let isConnectedDevice = bluetoothManager.connectedPeripheralID == discovered.peripheral.identifier
 
 Button(action: {
 bluetoothManager.connect(to: discovered.peripheral)
 }) {
 HStack {
 VStack(alignment: .leading) {
 Text(discovered.peripheral.name ?? "Unbekannt")
 Text("RSSI: \(discovered.rssi)")
 .font(.caption)
 .foregroundColor(.gray)
 
 if isConnectedDevice {
 Text("✅ Verbunden")
 .font(.caption2)
 .foregroundColor(.green)
 }
 }
 
 Spacer()
 
 Button(action: {
 if bluetoothManager.favoriteUUID == discovered.peripheral.identifier {
 bluetoothManager.favoriteUUID = nil
 } else {
 bluetoothManager.favoriteUUID = discovered.peripheral.identifier
 }
 }) {
 Image(systemName: bluetoothManager.favoriteUUID == discovered.peripheral.identifier ? "star.fill" : "star")
 .foregroundColor(.yellow)
 }
 .buttonStyle(.plain)
 }
 .padding(8)
 .background(isConnectedDevice ? Color.green.opacity(0.2) : Color.clear)
 }
 }
 }
 .padding(.horizontal)
 }
 }
 .frame(height: geometry.size.height * 0.5)
 .background(Color(UIColor.systemBackground))
 .cornerRadius(8)
 
 // USB Devices (50%)
 VStack(alignment: .leading, spacing: 0) {
 Text("USB Devices")
 .font(.headline)
 .foregroundColor(.white)
 .padding()
 .frame(maxWidth: .infinity)
 .background(Color.gray.opacity(0.8))
 
 ScrollView {
 VStack(alignment: .leading, spacing: 10) {
 Text("External HDD")
 Text("USB-C Hub")
 Text("Flash Drive")
 }
 .padding(.horizontal)
 }
 }
 .frame(height: geometry.size.height * 0.5)
 .background(Color(UIColor.systemBackground))
 .cornerRadius(8)
 
 }
 }
 }
 .navigationTitle("Geräte verbinden")
 .padding()
 }
 }
 
 
 struct DeviceListView_Previews: PreviewProvider {
 static var previews: some View {
 DeviceListView(bluetoothManager: MockBluetoothManager())
 }
 }
 */
