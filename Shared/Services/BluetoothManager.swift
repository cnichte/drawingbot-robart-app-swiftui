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

    var connectedPeripheralID: UUID? {
        return hm10Peripheral?.identifier
    }
    
    var connectedPeripheralName: String {
        return hm10Peripheral?.name ?? "Unbekannt"
    }
    
    @Published var peripherals: [DiscoveredPeripheral] = []
    @Published var receivedMessage: String = ""
    
    @Published var isBluetoothReady = false
    @Published var isConnected = false
    @Published var lastScanDate: Date? = nil
    @Published var isScanning: Bool = false
    
    @Published var favoriteUUID: UUID? = nil
    @Published var rssi: NSNumber? = nil
    
    private var centralManager: CBCentralManager!
    private var hm10Peripheral: CBPeripheral?
    private var txCharacteristic: CBCharacteristic?
    private var lastConnectedUUID: UUID?
    private var filterByService = true

    let hm10ServiceUUID = CBUUID(string: "FFE0")
    let hm10CharUUID = CBUUID(string: "FFE1")

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        print("BluetoothManager init wurde aufgerufen ✅")
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOn:
            isBluetoothReady = true
            print("✅ Bluetooth ist eingeschaltet")
            // Starte Scannen oder andere Operationen hier
        case .poweredOff:
            isBluetoothReady = false
            print("❌ Bluetooth ist ausgeschaltet")
        case .unauthorized:
            isBluetoothReady = false
            print("❌ Bluetooth-Berechtigung fehlt")
        case .unsupported:
            isBluetoothReady = false
            print("❌ Bluetooth wird nicht unterstützt")
        default:
            isBluetoothReady = false
            print("❌ Unbekannter Bluetooth-Zustand")
        }
        
        if central.state == .poweredOn {
            startScan()
        }
    }

    func startScan(filter: Bool? = nil) {
        
        guard let centralManager = centralManager, centralManager.state == .poweredOn else {
            print("❌ Kann nicht scannen: Bluetooth ist nicht bereit")
            return
        }
        
        filterByService = filter ?? filterByService
        peripherals.removeAll()
        centralManager.stopScan()
        isScanning = true
        print("🔍 Starte Scan (\(filterByService ? "nur HM-10" : "alle Geräte"))\n")

        if filterByService {
            centralManager.scanForPeripherals(withServices: [hm10ServiceUUID], options: nil)
            lastScanDate = Date()
        } else {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            lastScanDate = Date()
        }

        // ⏱ Scan automatisch nach 5 Sekunden stoppen
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.centralManager.stopScan()
            self.isScanning = false
            print("🛑 Scan automatisch gestoppt\n")
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print("❌ Fehler beim Verbinden mit Gerät \(peripheral.name ?? "Unbekannt\n"): \(error.localizedDescription)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let name = peripheral.name else { return }

        print("Gefundenes Gerät: \(name)")
        print("Advertisement Data: \(advertisementData)\n\n")

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

        if !isConnected, let lastUUID = favoriteUUID ?? lastConnectedUUID, peripheral.identifier == lastUUID {
            connect(to: peripheral)
        }
    }

    func connect(to peripheral: CBPeripheral) {
        centralManager.stopScan()
        isScanning = false
        hm10Peripheral = peripheral
        peripheral.delegate = self
        lastConnectedUUID = peripheral.identifier
        centralManager.connect(peripheral, options: nil)
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Verbunden mit \(peripheral.name ?? "Unbekannt")\n")
        isConnected = true
        peripheral.readRSSI()
        peripheral.discoverServices([hm10ServiceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        isConnected = false
        hm10Peripheral = nil
        txCharacteristic = nil
        peripherals.removeAll()

        if let error = error {
            print("❌ Fehler beim Trennen von Gerät \(peripheral.name ?? "Unbekannt\n"): \(error.localizedDescription)\n")
        }

        // automatischer Scan nach Disconnect
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.startScan()
         }
    }

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

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value, let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.receivedMessage += message
            }
        }
    }

    func send(_ text: String) {
        guard let peripheral = hm10Peripheral,
              let characteristic = txCharacteristic,
              let data = text.data(using: .utf8) else { return }

        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }

    func disconnect() {
        if let peripheral = hm10Peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            hm10Peripheral = nil
            isConnected = false
            // Verhindere neuen Scan direkt nach Disconnect
            
            // Rücksetzen der Favoriten und der letzten verbundenen UUID
            favoriteUUID = nil
            lastConnectedUUID = nil
        }
    }
}
