//
//  ConnectionStatusHeader.swift
//  Robart
//
//  Created by Carsten Nichte on 27.04.25.
//

// Shared/Views/ConnectionStatusHeader.swift
// ConnectionStatusHeader.swift
import SwiftUI

struct ConnectionStatusHeader: View {
    @EnvironmentObject var bluetoothManager: BluetoothManager
    @EnvironmentObject var assetStores: AssetStores
#if os(macOS)
    @EnvironmentObject var usbScanner: USBSerialScanner
#endif
    
    private var connectedName: String {
        bluetoothManager.connectedPeripheralName // FEHLER!
    }

    var body: some View {
        HStack(spacing: 12) {
            bluetoothStatus
#if os(macOS)
            Divider().frame(height: 20)
            usbStatus
#endif
            Divider().frame(height: 20)
            storageStatus
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(ColorHelper.backgroundColor)
        .font(.footnote)
        .frame(minHeight: 28, maxHeight: 32)
    }

    // MARK: - Bluetooth Status
    private var bluetoothStatus: some View {
        HStack(spacing: 6) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundColor(bluetoothManager.isConnected ? .green : .secondary)

            if bluetoothManager.isConnected {
                Text("Bluetooth verbunden")
                    .foregroundColor(.green)
                    .help("Verbunden mit \(connectedName.isEmpty ? "Unbekannt" : connectedName)")

                Button {
                    bluetoothManager.disconnect()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("Bluetooth-Verbindung trennen")
            } else {
                Text("Bluetooth getrennt")
                    .foregroundColor(.secondary)
            }
        }
        .lineLimit(1)
        .fixedSize()
    }

    // MARK: - USB Status (nur macOS)
#if os(macOS)
    private var usbStatus: some View {
        HStack(spacing: 6) {
            Image(systemName: "externaldrive.connected.to.line.below")
                .foregroundColor(usbScanner.currentPort?.isOpen == true ? .blue : .secondary)

            if let usbPort = usbScanner.currentPort, usbPort.isOpen {
                Text("USB verbunden")
                    .foregroundColor(.blue)
                    .help("Verbunden mit \(usbPort.name)")
                Button {
                    usbPort.close()
                    usbScanner.currentPort = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .help("USB-Verbindung trennen")
            } else {
                Text("USB getrennt")
                    .foregroundColor(.secondary)
            }
        }
        .lineLimit(1)
        .fixedSize()
    }
#endif

    // MARK: - Storage Status
    private var storageStatus: some View {
        HStack(spacing: 8) {
            let currentStorage = assetStores.storageType

            Image(systemName: currentStorage == .local ? "internaldrive" : "icloud")
                .foregroundColor(.gray)
                .transition(.opacity)
                .id(currentStorage)

            Text("Store: \(currentStorage.rawValue)")
                .foregroundColor(.gray)
                .font(.footnote)

#if DEBUG
            Divider().frame(height: 20)

            Button(action: AppResetHelper.resetLocalOnly) {
                Image(systemName: "arrow.counterclockwise.circle")
            }
            .help("Nur lokalen Speicher leeren")

            Button(action: AppResetHelper.resetICloudOnly) {
                Image(systemName: "icloud.slash")
            }
            .help("Nur iCloud-Speicher leeren")

            Button(action: AppResetHelper.fullResetAll) {
                Image(systemName: "trash.circle")
            }
            .help("Alles komplett zurücksetzen")

            Button(action: {
                _ = Bundle.main.listAllJSONResources()
            }) {
                Image(systemName: "doc.text.magnifyingglass")
            }
            .help("JSON-Dateien im Bundle anzeigen")
#endif
        }
    }
}
