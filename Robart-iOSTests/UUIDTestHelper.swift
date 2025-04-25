//
//  UUIDTestHelper.swift
//  Robart
//
//  Created by Carsten Nichte on 25.04.25.
//

// UUIDTestHelper.swift

import Foundation

struct UUIDTestHelper {
    
    /// Gibt eine zufällige UUID zurück
    static var random: UUID {
        UUID()
    }
    
    /// Gibt eine leere (Null-)UUID zurück: 00000000-0000-0000-0000-000000000000
    static var zero: UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
    }
    
    /// Gibt eine Dummy-UUID zurück (z.B. für Vorschau-Modelle oder Tests)
    static var dummy: UUID {
        UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    }
    
    /// Gibt eine feste UUID für spezielle Tests
    static func fixed(_ string: String) -> UUID {
        UUID.from(string) ?? UUID()
    }
}
