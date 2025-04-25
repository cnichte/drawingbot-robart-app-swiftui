//
//  AppResetHelper.swift
//  Robart
//
//  Created by Carsten Nichte on 25.04.25.
//
// rm -rf ~/Library/Developer/Xcode/DerivedData
//  ⇧ + ⌘ + G (Gehe zu Ordner) -> suche de.nichte.Robart
// Menü: Xcode > Window > Devices and Simulators. Wähle deinen Simulator → Rechtsklick → Erase All Content and Settings
//  iCloud-Daten: ~/Library/Mobile Documents/iCloud~de~nichte~robart/Documents/
// Nur im Developer Modus nutzen.

// AppResetHelper.swift
import Foundation
import SwiftUI

struct AppResetHelper {
    
    static func resetUserDefaults() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: bundleID)
        UserDefaults.standard.synchronize()
        print("🧹 UserDefaults gelöscht.")
    }

    private static func resetFiles(for storageType: StorageType) {
        let service = FileManagerService()
        let subdirs = ["settings", "connections", "machines", "projects", "jobs", "pens", "papers"]
        let fm = FileManager.default

        for subdir in subdirs {
            if let dirURL = service.getDirectoryURL(for: storageType)?.appendingPathComponent(subdir),
               fm.fileExists(atPath: dirURL.path) {
                do {
                    try fm.removeItem(at: dirURL)
                    print("🗑️ Verzeichnis gelöscht: \(dirURL.lastPathComponent) (\(storageType.rawValue))")
                } catch {
                    print("❌ Fehler beim Löschen von \(dirURL.lastPathComponent): \(error)")
                }
            }
        }
    }
    
    
    static func resetLocalOnly() {
        print("🔁 Lokalen Speicher löschen...")
        deleteAll(in: .local)
    }

    static func resetICloudOnly() {
        print("🔁 iCloud Speicher löschen...")
        deleteAll(in: .iCloud)
    }

    static func fullResetAll() {
        print("🧨 Kompletter Reset...")
        deleteAll(in: .local)
        deleteAll(in: .iCloud)
        UserDefaults.standard.removeObject(forKey: "migrated_paper-format")
    }

    private static func deleteAll(in storage: StorageType) {
        let service = FileManagerService()
        let fileManager = FileManager.default
        let subdirs = ["connections", "machines", "projects", "jobs", "pens", "papers", "settings"]

        for subdir in subdirs {
            if let dirURL = service.getDirectoryURL(for: storage)?.appendingPathComponent(subdir) {
                if fileManager.fileExists(atPath: dirURL.path) {
                    do {
                        try fileManager.removeItem(at: dirURL)
                        print("🗑️ Gelöscht: \(dirURL.path)")
                    } catch {
                        print("❌ Fehler beim Löschen \(dirURL.path): \(error)")
                    }
                }
            }
        }
    }
}
