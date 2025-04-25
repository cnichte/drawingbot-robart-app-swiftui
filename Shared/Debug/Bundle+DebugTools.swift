//
//  Bundle+DebugTools.swift
//  Robart
//
//  Created by Carsten Nichte on 25.04.25.
//

// Bundle+DebugTools.swift
import Foundation

extension Bundle {
    func listAllJSONResources() -> [String] {
        let resourcePaths = paths(forResourcesOfType: "json", inDirectory: nil)

        if resourcePaths.isEmpty {
            print("⚠️ Keine JSON-Dateien im Bundle gefunden.")
        } else {
            print("\n🔎 Gefundene JSON-Dateien im Bundle:")
            for path in resourcePaths {
                let fileName = (path as NSString).lastPathComponent
                print("✅ \(fileName)")
            }
            print("📦 Insgesamt \(resourcePaths.count) JSON-Datei(en) gefunden.\n")
        }

        return resourcePaths.map { ($0 as NSString).lastPathComponent }
    }
}
