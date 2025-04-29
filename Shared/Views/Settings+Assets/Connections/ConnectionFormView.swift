//
//  ConnectionFormView.swift
//  Robart
//
//  Created by Carsten Nichte on 23.04.25.
//

// ConnectionFormView.swift
// MARK: - ConnectionData.swift (aktualisiert)
import Foundation
import SwiftUI

// MARK: - ConnectionFormView.swift (aktualisiert)
import SwiftUI

struct ConnectionFormView: View {
    // MARK: Bindings & Services
    @Binding var data: ConnectionData
    @EnvironmentObject var store: GenericStore<ConnectionData>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    #if os(macOS)
    @EnvironmentObject var scanner: USBSerialScanner
    #endif

    // MARK: Local UI‑State
    @State private var selectedBluetooth: DiscoveredPeripheral?
    #if os(macOS)
    @State private var selectedUSB: USBSerialDevice?
    #endif
    @State private var isScanningBT  = false
    @State private var isScanningUSB = false

    // MARK: View
    var body: some View {
        Form {
            detailsSection
            typeSection
            deviceSection
            Button("Speichern und verbinden", action: connectAndSave)
        }
        .platformFormPadding()
        .navigationTitle("Verbindung erstellen")
        .onAppear              { syncState() }
        .onChange(of: data.id) { syncState() }
        .onDisappear { bluetoothManager.cancelScan() }   // verhindert Dauerscan beim Verlassen
    }

    // MARK: Details ---------------------------------------------------------
    private var detailsSection: some View {
        Section {
            TextField("Name", text: $data.name)
                .platformTextFieldModifiers()
                .onChange(of: data.name) { save() }

            TextEditor(text: $data.description)
                .frame(minHeight: 100)
                .onChange(of: data.description) { save() }
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2)))
        } header: { Text("Details") }
    }

    // MARK: Verbindungstyp --------------------------------------------------
    private var typeSection: some View {
        Section {
            Picker("Typ", selection: $data.typ) {
                Text("Bluetooth").tag(ConnectionType.bluetooth)
                Text("USB").tag(ConnectionType.usb)
            }
            .pickerStyle(.segmented)
            .onChange(of: data.typ) { clearOppositeFields(); save(); syncState() }
        } header: { Text("Typ") }
    }

    // MARK: Geräte‑Picker ---------------------------------------------------
    private var deviceSection: some View {
        Section(header: Text("Gerät auswählen")) {
            if data.typ == .bluetooth {
                bluetoothPicker
            } else {
                #if os(macOS)
                usbPicker
                #else
                EmptyView()
                #endif
            }
        }
    }

    // MARK: Bluetooth Picker
    private var bluetoothPicker: some View {
        Group {
            if isScanningBT {
                ProgressView("Suche nach Bluetooth‑Geräten …")
            } else {
                Picker("Bluetooth", selection: $selectedBluetooth) {
                    btOptions()
                }
                .onAppear { ensureBTScan() }
                .onChange(of: selectedBluetooth) {  writeBTSelection() }
            }
        }
    }

    // MARK: USB Picker (macOS)
    #if os(macOS)
    private var usbPicker: some View {
        Group {
            if isScanningUSB {
                ProgressView("Suche nach USB‑Geräten …")
            } else {
                Picker("USB", selection: $selectedUSB) {
                    usbOptions()
                }
                .onAppear { ensureUSBScan() }
                .onChange(of: selectedUSB) { writeUSBSelection() }
            }
        }
    }
    #endif

    // MARK: Picker Optionen -------------------------------------------------
    @ViewBuilder private func btOptions() -> some View {
        // offline placeholder
        if let uuid = data.btPeripheralUUID, let name = data.btPeripheralName,
           !bluetoothManager.peripherals.contains(where: { $0.peripheral.identifier == uuid }) {
            Text("🔒 \(name) (offline)").tag(nil as DiscoveredPeripheral?)
        }
        ForEach(bluetoothManager.peripherals) { p in
            Text(p.peripheral.name ?? "Unbekannt").tag(p as DiscoveredPeripheral?)
        }
        Text("Kein Gerät auswählen").tag(nil as DiscoveredPeripheral?)
    }

    #if os(macOS)
    @ViewBuilder private func usbOptions() -> some View {
        if let sel = selectedUSB, !scanner.devices.contains(where: { $0.path == sel.path }) {
            Text("🔒 \(sel.name)").tag(sel as USBSerialDevice?)
        }
        ForEach(scanner.devices) { d in Text(d.name).tag(d as USBSerialDevice?) }
        Text("Kein Gerät auswählen").tag(nil as USBSerialDevice?)
    }
    #endif

    // MARK: Sync ------------------------------------------------------------
    private func syncState() {
        // BT
        if let uuid = data.btPeripheralUUID,
           let match = bluetoothManager.peripherals.first(where: { $0.peripheral.identifier == uuid }) {
            selectedBluetooth = match
        } else { selectedBluetooth = nil }

        // USB
        #if os(macOS)
        if let path = data.usbPath {
            if let dev = scanner.devices.first(where: { $0.path == path }) {
                selectedUSB = dev
            } else {
                selectedUSB = USBSerialDevice(path: path,
                                             vendorID: data.usbVendorID,
                                             productID: data.usbProductID,
                                             description: data.usbName ?? "Offline‑USB")
            }
        } else { selectedUSB = nil }
        #endif
    }

    private func clearOppositeFields() {
        switch data.typ {
        case .bluetooth:
            data.usbVendorID = nil; data.usbProductID = nil; data.usbPath = nil; data.usbName = nil; data.usbDesc = nil
        case .usb:
            data.btPeripheralUUID = nil; data.btPeripheralName = nil; data.btServiceUUID = nil
        }
    }

    // MARK: Write Selection -------------------------------------------------
    private func writeBTSelection() {
        guard let p = selectedBluetooth else { return }
        data.btPeripheralUUID  = p.peripheral.identifier
        data.btPeripheralName  = p.peripheral.name
        save()
    }

    #if os(macOS)
    private func writeUSBSelection() {
        guard let d = selectedUSB else { return }
        data.usbPath      = d.path
        data.usbVendorID  = d.vendorID
        data.usbProductID = d.productID
        data.usbName      = d.name
        data.usbDesc      = d.description
        save()
    }
    #endif

    // MARK: Scan Trigger ----------------------------------------------------
    private func ensureBTScan() { if bluetoothManager.peripherals.isEmpty { startBTScan() } }
    private func startBTScan() { isScanningBT = true; bluetoothManager.startScan(filter: true); DispatchQueue.main.asyncAfter(deadline: .now() + 5) { isScanningBT = false } }

    #if os(macOS)
    private func ensureUSBScan() { if scanner.devices.isEmpty { startUSBScan() } }
    private func startUSBScan() { isScanningUSB = true; scanner.scanSerialDevices(); DispatchQueue.main.asyncAfter(deadline: .now() + 5) { isScanningUSB = false } }
    #endif

    // MARK: Verbinden & Speichern ------------------------------------------
    private func connectAndSave() {
        switch data.typ {
        case .bluetooth: if let p = selectedBluetooth { bluetoothManager.connect(to: p.peripheral) }

        case .usb:
#if os(macOS)
            if let d = selectedUSB { scanner.connect(to: d) }
#endif
        }
        save()
    }

    private func save() { Task { await store.save(item: data, fileName: data.id.uuidString) } }
}
