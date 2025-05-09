//
//  Bluetooth_Manager.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 07.04.25.
//

/* Was steckt drin:
 
 Scannen & Verbinden mit HM-10
 Senden von Textnachrichten an Arduino
 Empfangen & Anzeigen von Daten vom Arduino (live)
 
 Scan nach BLE-Geräten (mit/ohne Filter)
 Automatischer Reconnect zum letzten Gerät
 @Published Properties für View-Bindings:
 peripherals, receivedMessage, isConnected, isScanning, rssi
 Automatischer Scan-Restart nach Disconnect
 Sortierung der Geräte nach RSSI
 Kommunikation mit HM-10 (UUID FFE0/FFE1)
 
 Scan wird nach 5 Sekunden automatisch beendet
 lastScanDate (Datum/Uhrzeit des letzten Scans wird mitgeführt
 Log-Ausgaben zur Laufzeit (z. B. „Scan automatisch gestoppt"
 
 Favoriten support
 Es wird automatisch zum zuletzt gespeicherten Favoriten verbunden.
 lastScanDate wird für alle Scan-Modi korrekt gesetzt.
 
 */

// BluetoothManager.swift
import Foundation
import CoreBluetooth

// MARK: - DiscoveredPeripheral

struct DiscoveredPeripheral: Identifiable, Hashable {
    let id = UUID()
    let peripheral: CBPeripheral
    let rssi: NSNumber
    
    // Implementiere Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(peripheral.identifier)
    }

    // Implementiere Equatable für den Vergleich
    static func ==(lhs: DiscoveredPeripheral, rhs: DiscoveredPeripheral) -> Bool {
        return lhs.peripheral.identifier == rhs.peripheral.identifier
    }
}

// MARK: - BluetoothManager

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private var scanWorkItem: DispatchWorkItem?
    private let defaultScanDuration: TimeInterval = 5.0

    @Published var peripherals: [DiscoveredPeripheral] = [] // discoveredPeripherals Verwende den DiscoveredPeripheral-Typ
    @Published var receivedMessage: String = ""
    @Published var isBluetoothReady = false
    @Published var isConnected = false
    @Published var lastScanDate: Date? = nil
    @Published var isScanning: Bool = false
    @Published var rssi: NSNumber? = nil
    
    @Published var favoriteUUID: UUID? //TODO: deprecated ??

    private var centralManager: CBCentralManager!
    private var txCharacteristic: CBCharacteristic?
    private var filterByService = true
    private var rssiTimer: Timer?
    
    // Das ist EINE Verbindung zu Robart...
    private var hm10Peripheral: CBPeripheral?
    let hm10ServiceUUID = CBUUID(string: "FFE0")
    let hm10CharUUID = CBUUID(string: "FFE1")

    var connectedPeripheralID: UUID? {
        return hm10Peripheral?.identifier
    }

    var connectedPeripheralName: String {
        return hm10Peripheral?.name ?? ""
    }
    
    /// Enthält alle aktuell verbundenen Peripherie-UUIDs
    @Published var connectedPeripheralIDs: Set<UUID> = []
    
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        appLog(.info, "BluetoothManager init wurde aufgerufen ✅")
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothReady = (central.state == .poweredOn)
        appLog(.info, isBluetoothReady ? "✅ Bluetooth ist eingeschaltet" : "❌ Bluetooth ist nicht bereit")
        if isBluetoothReady {
            startScan()
        }
    }

    private func startRSSIMonitoring() {
        rssiTimer?.invalidate()
        rssiTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.hm10Peripheral?.readRSSI()
        }
    }
    
    // RSSIMonitoring Delegate-Callback
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else { return }
        DispatchQueue.main.async { self.rssi = RSSI }
    }
    
    // startScan(filter:duration:) ersetzen
    func startScan(filter: Bool? = nil, duration: TimeInterval? = nil) {
        guard let central = centralManager, central.state == .poweredOn else { return }

        filterByService = filter ?? filterByService
        peripherals.removeAll()

        // 1) evtl. laufenden Scan + Timer beenden
        central.stopScan()
        scanWorkItem?.cancel()

        isScanning = true

        // 2) Scan starten
        if filterByService {
            central.scanForPeripherals(withServices: [hm10ServiceUUID], options: nil)
        } else {
            central.scanForPeripherals(withServices: nil, options: nil)
        }
        lastScanDate = Date()

        // 3) Timer zum automatischen Stoppen
        let work = DispatchWorkItem { [weak self] in
            self?.centralManager.stopScan()
            self?.isScanning = false
            self?.scanWorkItem = nil
        }
        scanWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + (duration ?? defaultScanDuration), execute: work)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else { return }

        if filterByService {
            if !(name.uppercased().contains("HM") || name.uppercased().contains("BLE") || advertisementData.description.contains("HM")) {
                return
            }
        }

        if !peripherals.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
            DispatchQueue.main.async {
                self.peripherals.append(DiscoveredPeripheral(peripheral: peripheral, rssi: RSSI))
                self.peripherals.sort { $0.rssi.intValue > $1.rssi.intValue }
            }
        }

        // Auto-Reconnect wenn Connection existiert
        if !isConnected, let match = AssetStores.shared.connectionsStore.items.first(where: { $0.name == name }) {
            connect(to: peripheral)
            ConnectionManager.shared.connect(connection: match)
        }
    }

    func connect(to peripheral: CBPeripheral) {
        centralManager.stopScan()
        isScanning = false
        hm10Peripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        appLog(.info, "✅ Verbunden mit \(peripheral.name ?? "Unbekannt")")
        isConnected = true
        peripheral.readRSSI()
        peripheral.discoverServices([hm10ServiceUUID])
        startRSSIMonitoring()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        hm10Peripheral = nil
        txCharacteristic = nil
        peripherals.removeAll()

        if let name = peripheral.name, let match = AssetStores.shared.connectionsStore.items.first(where: { $0.name == name }) {
            ConnectionManager.shared.disconnect(connection: match)
            rssiTimer?.invalidate()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startScan()
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services where service.uuid == hm10ServiceUUID {
            peripheral.discoverCharacteristics([hm10CharUUID], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics where characteristic.uuid == hm10CharUUID {
            txCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }

    func send(_ text: String) {
        guard let peripheral = hm10Peripheral,
              let characteristic = txCharacteristic,
              let data = text.data(using: .utf8) else { return }

        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }

    func cancelScan() {
        centralManager.stopScan()
        scanWorkItem?.cancel()
        scanWorkItem = nil
        isScanning = false
    }
    
    /// Verbindung trennen
    func disconnect() {
        if let peripheral = hm10Peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        hm10Peripheral = nil
        isConnected = false
    }
}
