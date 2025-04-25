//
//  Bundle+DebugTools.swift
//  Robart
//
//  Created by Carsten Nichte on 25.04.25.
//

import Foundation

extension Bundle {
    /// Listet alle `.json`-Dateien im Haupt-Bundle auf.
    func listAllJSONResources() -> [String] {
        guard let resourceURLs = urls(forResourcesWithExtension: "json", subdirectory: nil) else {
            print("📭 Keine JSON-Dateien im Bundle gefunden.")
            return []
        }

        let fileNames = resourceURLs.map { $0.lastPathComponent }
        print("📦 JSON-Dateien im Bundle:")
        for name in fileNames {
            print("  • \(name)")
        }
        return fileNames
    }
}
