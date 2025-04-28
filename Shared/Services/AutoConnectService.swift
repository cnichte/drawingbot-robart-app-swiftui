//
//  AutoConnectService.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// AutoConnectService.swift
import Foundation

class AutoConnectService: ObservableObject {
    static let shared = AutoConnectService()

    private init() {}

    func tryAutoConnectBluetooth(bluetoothManager: BluetoothManager) {
        guard bluetoothManager.isBluetoothReady else { return }

        for discovered in bluetoothManager.peripherals {
            if let match = AssetStores.shared.connectionsStore.items.first(where: {
                $0.typ == .bluetooth && $0.name == (discovered.peripheral.name ?? "")
            }) {
                bluetoothManager.connect(to: discovered.peripheral)
                ConnectionManager.shared.connect(connection: match)
                appLog(.info, "🔗 Auto-Connect Bluetooth: Verbinde mit \(match.name)")
                return
            }
        }
    }

    func tryAutoConnectUSB(usbScanner: USBSerialScanner) {
        for device in usbScanner.devices {
            if let match = AssetStores.shared.connectionsStore.items.first(where: {
                $0.typ == .usb &&
                $0.usbVendorID == device.vendorID &&
                $0.usbProductID == device.productID
            }) {
                usbScanner.connect(to: device)
                ConnectionManager.shared.connect(connection: match)
                appLog(.info, "🔗 Auto-Connect USB: Verbinde mit \(match.name)")
                return
            }
        }
    }
}
