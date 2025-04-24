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
        self.name // or use self.path or self.name if more unique
    }
}
#endif

// DeviceSectionView.swift
struct DeviceSectionView<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.8))

            ScrollView {
                content()
                    .padding()
            }
        }
        .cornerRadius(8)
    }
}


struct DeviceListView: View {
    @ObservedObject var bluetoothManager: BluetoothManager
    
#if os(macOS)
    @StateObject private var scanner = USBSerialScanner()
#endif
    
    var body: some View {
        ScrollView {
        CollapsibleSection(title: "Bluetooth Devices", systemImage: "wave.3.up") {
            VStack(alignment: .leading, spacing: 8) {
                bluetoothSectionContent()
            }
        }
        
#if os(macOS)
        CollapsibleSection(title: "USB Devices", systemImage: "photo") {
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
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    Button("Scan nach RobArt (HM-10)") {
                        bluetoothManager.startScan(filter: true)
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Alle Geräte scannen") {
                        bluetoothManager.startScan(filter: false)
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, alignment: .leading) // fixierte Ausrichtung

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
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(bluetoothManager.peripherals) { discovered in
                    let isConnectedDevice = bluetoothManager.connectedPeripheralID == discovered.peripheral.identifier
                    let isFavorite = bluetoothManager.favoriteUUID == discovered.peripheral.identifier

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(discovered.peripheral.name ?? "Unbekannt")
                                .font(.headline)
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

                        VStack(spacing: 6) {
                            if isConnectedDevice {
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

                            Button {
                                bluetoothManager.favoriteUUID = isFavorite ? nil : discovered.peripheral.identifier
                            } label: {
                                Image(systemName: isFavorite ? "star.fill" : "star")
                                    .foregroundColor(.yellow)
                            }
                            .buttonStyle(.plain)
                            .help(isFavorite ? "Favorit entfernen" : "Als Favorit markieren")
                        }
                    }
                    .padding(8)
                    .background(isConnectedDevice ? Color.green.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2))
                    )
                }
            }
        }
        .frame(maxWidth: .infinity) // äußere View füllt die Breite
    }
    
    // MARK: - USB Section
    
    @ViewBuilder
    private func usbSectionContent() -> some View {
    #if os(macOS)
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("Geräte scannen") {
                    scanner.scanSerialDevices()
                }

                Button("Verbinden") {
                    scanner.connectToSelectedDevice()
                }
                .disabled(scanner.selectedDevice == nil)
            }

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
        VStack {
            Text("Sorry, USB-Serial wird auf iOS nicht unterstützt. Bitte bei Apple beschweren!")
                .foregroundColor(.gray)
                .padding()
        }
    #endif
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
