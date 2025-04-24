//
//  iCloudHelper.swift
//  Robart
//
//  Created by Carsten Nichte on 24.04.25.
//

import Foundation

class iCloudHelper {
    
    /// Prüft, ob iCloud verfügbar ist, und liefert den Container-URL zurück (oder nil).
    static func checkAvailability(completion: @escaping (URL?) -> Void) {
        DispatchQueue.global().async {
            let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)

            DispatchQueue.main.async {
                if let url = containerURL {
                    print("✅ iCloud verfügbar: \(url)")
                } else {
                    print("❌ iCloud nicht verfügbar oder nicht aktiviert")
                }
                completion(containerURL)
            }
        }
    }
}
