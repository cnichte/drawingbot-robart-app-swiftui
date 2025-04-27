//
//  AssetManagerHelper.swift
//  Robart
//
//  Created by Carsten Nichte on 27.04.25.
//

// AssetManagerHelper.swift
import Foundation

struct AssetManagerHelper {
    
    // MARK: - Rollbacks
    
    static func rollbackAllUserMigrations(for storageType: StorageType) {
        let resourceNames = ["papers", "paper-formats", "aspect-ratios", "units"]
        for name in resourceNames {
            FileManagerService.shared.rollbackUserResource(for: name, storageType: storageType)
        }
        print("🔄 Alle User-Migrationen zurückgesetzt für \(storageType.rawValue)")
    }
    
    static func rollbackSingleMigration(resourceName: String, storageType: StorageType) {
        FileManagerService.shared.rollbackUserResource(for: resourceName, storageType: storageType)
        print("🔄 Migration zurückgesetzt für \(resourceName)")
    }
    
    // MARK: - Hard Reset
    
    static func deleteAllData(in assetStores: AssetStores) async {
        await assetStores.deleteAllLocalData()
        assetStores.resetAllStoresInMemory()
        print("🧹 Alle gespeicherten Dokumente wurden gelöscht und RAM zurückgesetzt.")
    }
    
    // MARK: - Soft Reset
    
    static func resetAllInMemory(in assetStores: AssetStores) {
        assetStores.resetAllStoresInMemory()
        print("🔁 RAM-Daten zurückgesetzt (Soft Reset).")
    }
    
    // MARK: - Utilities
    
    static func printSummary(of assetStores: AssetStores) {
        assetStores.printSummary()
    }
}
