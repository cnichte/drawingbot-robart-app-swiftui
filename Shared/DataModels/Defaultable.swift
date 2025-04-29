//
//  Defaultable.swift
//  Robart
//
//  Created by Carsten Nichte on 29.04.25.
//

// Defaultable.swift
import Foundation

// MARK: - Standard-Protokoll

/// Gibt an, dass eine Datenklasse einen `default`-Wert und einen schnellen `isDefault`-Vergleich unterstützt.
protocol Defaultable: Identifiable, Equatable {
    /// Der definierte Standardwert für den Typ.
    static var `default`: Self { get }
}

extension Defaultable {
    /// Gibt zurück, ob das Objekt der definierte Default ist.
    var isDefault: Bool {
        return self.id == Self.default.id
    }
}
