//
//  MachineCommandResolver.swift
//  Robart
//
//  Created by Carsten Nichte on 03.05.25.
//

// MachineCommandResolver.swift
final class MachineCommandResolver {
    private let commands: [String: MachineCommandItem]

    init(commandItems: [MachineCommandItem]) {
        self.commands = Dictionary(uniqueKeysWithValues: commandItems.map { ($0.name, $0) })
    }

    func resolve(name: String, variables: [String: CustomStringConvertible]) -> String? {
        guard let template = commands[name]?.command else { return nil }
        let resolved = replaceVariables(in: template, with: variables)
        
        // Überprüfen, ob alle Platzhalter ersetzt wurden
        if resolved.contains("{") {
            return nil // Es gibt noch unersetzte Platzhalter → Fehler
        }
        return resolved
    }

    func hasTemplate(name: String) -> Bool {
        return commands[name] != nil
    }

    private func replaceVariables(in template: String, with variables: [String: CustomStringConvertible]) -> String {
        var result = template
        for (key, value) in variables {
            result = result.replacingOccurrences(of: "{\(key)}", with: value.description)
        }
        return result
    }
}
