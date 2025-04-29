//
//  ConnectionFormView.swift
//  Robart
//
//  Created by Carsten Nichte on 23.04.25.
//

// ConnectionFormView.swift
import SwiftUI

struct ConnectionFormView: View {
    // MARK: - Bindings & Dependencies
    @Binding var data: ConnectionData
    @EnvironmentObject var store: GenericStore<ConnectionData>
    @EnvironmentObject var bluetoothManager: BluetoothManager
    #if os(macOS)
    @EnvironmentObject var scanner: USBSerialScanner
    #endif

    // MARK: - UI-State
    @State private var selectedBluetoothPeripheral: DiscoveredPeripheral?
    @State private var selectedUSBDevice: USBSerialDevice?
    @State private var isScanningBluetooth = false
    @State private var isScanningUSB       = false

    // MARK: - View
    var body: some View {
        Form {
            detailsSection
            typeSection
            deviceSection
            saveAndConnectButton
        }
        .platformFormPadding()
        .navigationTitle("Verbindung erstellen")
        .onAppear            { syncStateWithData() }
        .onChange(of: data.id) { _ in syncStateWithData() }
        .onReceive(store.$refreshTrigger) { _ in /* Re-Render */ }
    }

    // MARK: - Sections --------------------------------------------------------

    private var detailsSection: some View {
        Section {
            TextField("Name", text: $data.name)
                .platformTextFieldModifiers()
                .onChange(of: data.name) { _ in save() }

            TextEditor(text: $data.description)
                .frame(minHeight: 100)
                .onChange(of: data.description) { _ in save() }
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(0.2)))
        } header: {
            Text("Details")
        }
    }

    private var typeSection: some View {
        Section(header: Text("Typ")) {
            Picker("Typ", selection: $data.typ) {
                Text("Bluetooth").tag(ConnectionType.bluetooth)
                Text("USB").tag(ConnectionType.usb)
            }
            .pickerStyle(.segmented)
            .onChange(of: data.typ) { _ in
                clearOppositeFields()
                save()
                syncStateWithData()
            }
        }
    }

    private var deviceSection: some View {
        Section(header: Text("Gerät auswählen")) {
            if data.typ == .bluetooth {
                bluetoothPicker
            } else {
                #if os(macOS)
                usbPicker
                #endif
            }
        }
    }

    private var saveAndConnectButton: some View {
        Button("Speichern und verbinden") {
            connectAndSave()
        }
    }

    // MARK: - Bluetooth Picker -------------------------------------------------

    private var bluetoothPicker: some View {
        Group {
            if isScanningBluetooth {
                ProgressView("Suche nach Bluetooth-Geräten…")
            } else {
                Picker("Bluetooth", selection: $selectedBluetoothPeripheral) {
                    bluetoothOptions()
                }
                .onAppear { prepareBluetooth() }
                .onChange(of: selectedBluetoothPeripheral) { _ in
                    updateBluetoothSelection()
                }
            }
        }
    }

    // MARK: - USB Picker (macOS) ----------------------------------------------
    #if os(macOS)
    private var usbPicker: some View {
        Group {
            if isScanningUSB {
                ProgressView("Suche nach USB-Geräten…")
            } else {
                Picker("USB", selection: $selectedUSBDevice) {
                    usbOptions()
                }
                .onAppear { prepareUSB() }
                .onChange(of: selectedUSBDevice) { _ in
                    updateUSBSelection()
                }
            }
        }
    }
    #endif

    // MARK: - Picker-Optionen --------------------------------------------------

    @ViewBuilder
    private func bluetoothOptions() -> some View {
        let savedName = data.name
        if !savedName.isEmpty,
           !bluetoothManager.peripherals.contains(where: { $0.peripheral.name == savedName }) {
            Text("🔒 \(savedName) (gespeichert)")
                .tag(nil as DiscoveredPeripheral?)
        }

        ForEach(bluetoothManager.peripherals) { p in
            Text(p.peripheral.name ?? "Unbekannt")
                .tag(p as DiscoveredPeripheral?)
        }

        Text("Kein Gerät auswählen").tag(nil as DiscoveredPeripheral?)
    }

    #if os(macOS)
    @ViewBuilder
    private func usbOptions() -> some View {
        if let vid = data.usbVendorID,
           let pid = data.usbProductID,
           !scanner.devices.contains(where: { $0.vendorID == vid && $0.productID == pid }) {
            Text("🔒 \(data.usbPath ?? "Offline-USB")")
                .tag(nil as USBSerialDevice?)
        }

        ForEach(scanner.devices) { d in
            Text(d.name).tag(d as USBSerialDevice?)
        }

        Text("Kein Gerät auswählen").tag(nil as USBSerialDevice?)
    }
    #endif

    // MARK: - Sync & Helper ----------------------------------------------------

    /// Gleicht lokale Picker-States mit gespeicherten ConnectionData ab.
    private func syncStateWithData() {
        // Bluetooth
        if let uuid = data.btPeripheralUUID,
           let match = bluetoothManager.peripherals.first(where: { $0.peripheral.identifier == uuid }) {
            selectedBluetoothPeripheral = match
        } else {
            selectedBluetoothPeripheral = nil
        }

        // USB
        #if os(macOS)
        if let vid = data.usbVendorID,
           let pid = data.usbProductID,
           let match = scanner.devices.first(where: { $0.vendorID == vid && $0.productID == pid }) {
            selectedUSBDevice = match
        } else {
            selectedUSBDevice = nil
        }
        #endif
    }

    /// Entfernt nicht benötigte Felder je nach aktivem Verbindungstyp.
    private func clearOppositeFields() {
        switch data.typ {
        case .bluetooth:
            data.usbVendorID  = nil
            data.usbProductID = nil
            data.usbPath      = nil
        case .usb:
            data.btPeripheralUUID = nil
            data.btServiceUUID    = nil
        }
    }

    // MARK: - Auswahl-Updates --------------------------------------------------

    private func updateBluetoothSelection() {
        if let p = selectedBluetoothPeripheral {
            data.name             = p.peripheral.name ?? "Unbekannt"
            data.btPeripheralUUID = p.peripheral.identifier
        } else {
            data.btPeripheralUUID = nil
        }
        save()
    }

    #if os(macOS)
    private func updateUSBSelection() {
        if let d = selectedUSBDevice {
            data.name         = d.description
            data.usbVendorID  = d.vendorID
            data.usbProductID = d.productID
            data.usbPath      = d.path
        } else {
            data.usbVendorID = nil
            data.usbProductID = nil
            data.usbPath = nil
        }
        save()
    }
    #endif

    // MARK: - Scan-Trigger -----------------------------------------------------

    private func prepareBluetooth() {
        if bluetoothManager.peripherals.isEmpty { startBluetoothScan() }
    }

    #if os(macOS)
    private func prepareUSB() {
        if scanner.devices.isEmpty { startUSBScan() }
    }
    #endif

    private func startBluetoothScan() {
        isScanningBluetooth = true
        bluetoothManager.startScan(filter: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            isScanningBluetooth = false
        }
    }

    #if os(macOS)
    private func startUSBScan() {
        isScanningUSB = true
        scanner.scanSerialDevices()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            isScanningUSB = false
        }
    }
    #endif

    // MARK: - Verbinden & Speichern -------------------------------------------

    private func connectAndSave() {
        switch data.typ {
        case .bluetooth:
            if let p = selectedBluetoothPeripheral {
                bluetoothManager.connect(to: p.peripheral)
            }
        case .usb:
            #if os(macOS)
            if let d = selectedUSBDevice {
                scanner.connect(to: d)
            }
            #endif
        }
        save()
    }

    private func save() {
        Task {
            await store.save(item: data, fileName: data.id.uuidString)
        }
    }
}
