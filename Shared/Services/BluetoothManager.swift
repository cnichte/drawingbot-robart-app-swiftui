//
//  Bluetooth_Manager.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 07.04.25.
//

//  Bluetooth_Manager.swift
import Foundation
import CoreBluetooth

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

struct DiscoveredPeripheral: Identifiable {
    let id = UUID()
    let peripheral: CBPeripheral
    let rssi: NSNumber
}

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @Published var peripherals: [DiscoveredPeripheral] = []
    @Published var isConnected = false
    @Published var isScanning = false
    @Published var isBluetoothReady = false
    @Published var lastScanDate: Date? = nil
    @Published var rssi: NSNumber? = nil

    private var centralManager: CBCentralManager!
    private var hm10Peripheral: CBPeripheral?
    private var txCharacteristic: CBCharacteristic?
    private var filterByService = true
    
    var connectedPeripheralID: UUID? {
        return hm10Peripheral?.identifier
    }
    
    var connectedPeripheralName: String {
        return hm10Peripheral?.name ?? ""
    }
    
    private let hm10ServiceUUID = CBUUID(string: "FFE0")
    private let hm10CharUUID = CBUUID(string: "FFE1")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    func startScan(filter: Bool? = nil) {
        guard let centralManager, centralManager.state == .poweredOn else {
            appLog("❌ Bluetooth nicht bereit")
            return
        }
        
        filterByService = filter ?? filterByService
        peripherals.removeAll()
        centralManager.stopScan()
        isScanning = true
        lastScanDate = Date()

        appLog("🔍 Starte Scan (\(filterByService ? "nur HM-10" : "alle Geräte"))")

        if filterByService {
            centralManager.scanForPeripherals(withServices: [hm10ServiceUUID], options: nil)
        } else {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.centralManager.stopScan()
            self.isScanning = false
            appLog("🛑 Scan automatisch gestoppt")
        }
    }
    
    func connect(to peripheral: CBPeripheral) {
        centralManager.stopScan()
        isScanning = false
        hm10Peripheral = peripheral
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        if let peripheral = hm10Peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        hm10Peripheral = nil
        isConnected = false
    }
    
    func send(_ text: String) {
        guard let characteristic = txCharacteristic,
              let data = text.data(using: .utf8),
              let peripheral = hm10Peripheral else { return }
        
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    // MARK: - CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        isBluetoothReady = (central.state == .poweredOn)
        appLog(isBluetoothReady ? "✅ Bluetooth bereit" : "❌ Bluetooth nicht verfügbar")
        
        if isBluetoothReady {
            startScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else { return }
        
        if filterByService {
            if !(name.uppercased().contains("HM") || name.uppercased().contains("BLE") || advertisementData.description.contains("HM")) {
                return
            }
        }
        
        DispatchQueue.main.async {
            if !self.peripherals.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
                self.peripherals.append(DiscoveredPeripheral(peripheral: peripheral, rssi: RSSI))
                self.peripherals.sort { $0.rssi.intValue > $1.rssi.intValue }
            }
        }
        
        // Auto-Reconnect prüfen
        if !isConnected,
           let match = AssetStores.shared.connectionsStore.items.first(where: { $0.name == name && $0.typ == .bluetooth }) {
            connect(to: peripheral)
            ConnectionManager.shared.connect(connection: match)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        peripheral.delegate = self
        peripheral.readRSSI()
        peripheral.discoverServices([hm10ServiceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        hm10Peripheral = nil
        txCharacteristic = nil
        peripherals.removeAll()

        if let name = peripheral.name,
           let match = AssetStores.shared.connectionsStore.items.first(where: { $0.name == name && $0.typ == .bluetooth }) {
            ConnectionManager.shared.disconnect(connection: match)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startScan()
        }
    }
    
    // MARK: - CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        DispatchQueue.main.async {
            self.rssi = RSSI
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
}
