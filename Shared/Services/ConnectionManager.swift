//
//  ConnectionManager.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// ConnectionManager.swift
import Foundation

class ConnectionManager: ObservableObject {
    static let shared = ConnectionManager()

    @Published var activeConnections: [UUID: ConnectionData] = [:] // UUID der Connection → ConnectionData

    private init() {}

    func connect(connection: ConnectionData) {
        activeConnections[connection.id] = connection
        AssetStores.shared.updateMachineConnectionStatus(for: connection, isConnected: true)
    }

    func disconnect(connection: ConnectionData) {
        activeConnections.removeValue(forKey: connection.id)
        AssetStores.shared.updateMachineConnectionStatus(for: connection, isConnected: false)
    }

    func isConnected(_ connection: ConnectionData) -> Bool {
        return activeConnections[connection.id] != nil
    }
}
