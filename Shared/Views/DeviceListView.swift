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
    @StateObject private var scanner = USBSerialScanner()  // Nur auf macOS verwenden
#endif
    
    private func formatted(_ date: Date?) -> String {
        guard let d = date else { return "–" }
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .medium
        return df.string(from: d)
    }
    
    var body: some View {
        ScrollView {
            CollapsibleSection(
                title: "Bluetooth Devices",
                systemImage: "wave.3.up",
                toolbar: {
                    HStack(spacing: 8) {
                        // Scan RobArt
                        CustomToolbarButton(title: "", icon: "exclamationmark.magnifyingglass", style: .secondary, role: nil,hasBorder:false, iconSize: .large ) {
                            startBluetoothScan(filter: true)
                        }
                        // Scan Alle Geräte
                        CustomToolbarButton(title: "", icon: "sparkle.magnifyingglass", style: .primary, role: nil,hasBorder:false, iconSize: .large ) {
                            startBluetoothScan(filter: false)
                        }
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
        VStack(alignment: .leading, spacing: 6) {
            
            // Letzter Scan ▼
            Text("Letzter Scan: \(formatted(bluetoothManager.lastScanDate))")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if bluetoothManager.isScanning {
                ProgressView("Suche nach Bluetooth-Geräten…")
            } else {
                ForEach(bluetoothManager.peripherals) { discovered in
                    let isCurrent   = bluetoothManager.connectedPeripheralID == discovered.peripheral.identifier
                    let currentRSSI = isCurrent
                    ? (bluetoothManager.rssi?.intValue ?? discovered.rssi.intValue)
                    : discovered.rssi.intValue
                    
                    HStack(spacing: 12) {
                        // ✔︎ wenn verbunden
                        if isCurrent {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }else{
                            Image(systemName: "checkmark.circle")
                                .foregroundColor(.gray)
                        }
                        
                        // RSSI-Anzeige  (-100 … 0 dBm)
                        Gauge(value: Double(currentRSSI), in: -100...0) { }
                        currentValueLabel: { Text("\(currentRSSI) dBm").font(.caption2) }
                            .gaugeStyle(.accessoryLinearCapacity)
                            .frame(width: 70)
                        
                        Text(discovered.peripheral.name ?? "Unbekannt")
                        
                        Spacer()
                        // beende, verbinde
                        CustomButton(title: (isCurrent ? "" : ""), icon:(isCurrent ? "personalhotspot" : "personalhotspot.slash"), style: .secondary ){
 
                            isCurrent
                            ? bluetoothManager.disconnect()
                            : bluetoothManager.connect(to: discovered.peripheral)
                            
                        }
                    }
                }
            }
            
            Spacer()
        }
    }
    
#if os(macOS)
    // MARK: - USB Section
    @ViewBuilder
    private func usbSectionContent() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            
            // Letzter Scan ▼
            Text("Letzter Scan: \(formatted(scanner.lastScanDate))")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if scanner.isScanning {
                ProgressView("Suche nach USB-Geräten…")
            } else {
                ForEach(scanner.devices) { device in
                    let isCurrent = scanner.connectedDevice?.id == device.id
                    let portOpen  = isCurrent && scanner.isPortOpen
                    let baud      = isCurrent
                    ? (scanner.currentPort?.baudRate.intValue ?? scanner.defaultBaudRate)
                    : scanner.defaultBaudRate
                    
                    HStack(spacing: 12) {
                        if isCurrent {
                            Image(systemName: portOpen
                                  ? "externaldrive.fill.badge.checkmark"
                                  : "externaldrive.badge.xmark")
                            .foregroundColor(portOpen ? .green : .red)
                        }else{
                            Image(systemName: "externaldrive.fill")
                            .foregroundColor(.gray)
                        }
                        
                        // Geräteinfos
                        VStack(alignment: .leading, spacing: 2) {
                            Text(device.description)
                            Text(device.path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Baudrate: \(baud) Baud")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if let vID = device.vendorID, let pID = device.productID {
                                Text("VID: \(vID), PID: \(pID)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Button(isCurrent ? "Beenden" : "Verbinden") {
                            isCurrent
                            ? scanner.disconnect()
                            : scanner.connect(to: device)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            Spacer()
        }
        .onAppear {
            if scanner.devices.isEmpty && !scanner.isScanning {
                startUSBScan()
            }
        }
        .onDisappear { bluetoothManager.cancelScan() }   // verhindert Dauerscan beim Verlassen
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
