//
//  UUID+Helpers.swift
//  Robart
//
//  Created by Carsten Nichte on 25.04.25.
//

// Usage:
// let myForcedUUID   = UUID.force("7e3eb341-cee9-4da6-8acb-677d5cb19e13") // → crasht bei Fehler
// let mySafeUUID     = UUID.safe("abc123") // → nil
// let myFallbackUUID = UUID.fallback("abc123") // → generiert neue UUID
//
// let valid = UUID.isValidUUID("7e3eb341-cee9-4da6-8acb-677d5cb19e13") // → true
// let invalid = UUID.isValidUUID("nicht-gültig") // → false

/* USAGE:
 
Nur prüfen:
if UUID.isValidUUID("7e3eb341-cee9-4da6-8acb-677d5cb19e13") {
    appLog(.info, "Gültige UUID!")
}

Versuchen zu erzeugen (z.B. in deinem `PaperFormat.default`)
do {
    let uuid = try UUID.from("7e3eb341-cee9-4da6-8acb-677d5cb19e13")
    appLog(.info, "Erzeugt: \(uuid)")
} catch {
    print(error.localizedDescription)
}
 
 if let uuid = UUID.safeFrom("7e3eb341-cee9-4da6-8acb-677d5cb19e13") {
     appLog(.info, "Gültige UUID: \(uuid)")
 } else {
     appLog(.info, "Ungültige UUID")
 }
 
*/


// UUID+Extension.swift
import Foundation

extension UUID {
    static func force(_ uuidString: String) -> UUID {
        guard let uuid = UUID(uuidString: uuidString) else {
            fatalError("❌ Ungültige UUID-Zeichenkette: \(uuidString)")
        }
        return uuid
    }
}

extension UUID {
    /// Gibt optional eine UUID zurück, falls der String gültig ist.
    static func safe(_ uuidString: String) -> UUID? {
        UUID(uuidString: uuidString)
    }

    /// Gibt eine gültige UUID zurück – entweder aus dem String oder eine neue (fallback).
    static func fallback(_ uuidString: String) -> UUID {
        UUID(uuidString: uuidString) ?? UUID()
    }
}

extension UUID {
    /// Versucht eine UUID aus einem String zu erzeugen, liefert optional zurück (nil bei Fehler).
    static func safeFrom(_ uuidString: String) -> UUID? {
        return UUID(uuidString: uuidString)
    }
}


extension UUID {
    /// Prüft, ob ein String eine gültige UUID darstellt.
    static func isValidUUID(_ uuidString: String) -> Bool {
        return UUID(uuidString: uuidString) != nil
    }
    
    /// Erzeugt eine UUID aus einem String, wirft einen Fehler bei ungültigem Format.
    static func from(_ uuidString: String) throws -> UUID {
        if let uuid = UUID(uuidString: uuidString) {
            return uuid
        } else {
            throw UUIDError.invalidFormat(uuidString)
        }
    }
    
    enum UUIDError: Error, LocalizedError {
        case invalidFormat(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidFormat(let input):
                return "Ungültige UUID: \(input)"
            }
        }
    }
}
