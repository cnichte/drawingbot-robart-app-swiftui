//
//  MachineData.swift
//  Robart
//
//  Created by Carsten Nichte on 15.04.25.
//

// Axidraw:
// plotten: copies-to-plot, page-delay
// setup: pen-height-up: 60%,  pen-height-down: 30%, Action: cycle up down, raise pen and motors off, toogle pen up and down.
// optionen
// speed drawing: 25%, pen-up 75? acceleration: standart, high ..., use constant speed when pen is down
// Pen Timing: Pen raising speed, pen lowwering speed (maximum, standard, slow, very slow, dead slow)
// optional delay

// MachineData.swift
import Foundation

// MARK: - MachineType

enum MachineType: String, Codable, CaseIterable {
    case xyPlotter = ".xyPlotter"
    case omnidirektionalPlotter = ".omnidirektionalPlotter"
    case vertikalPlotter = ".vertikalPlotter" // PolarGraph

    static var allCases: [MachineType] {
        return [.xyPlotter, .omnidirektionalPlotter, .vertikalPlotter]
    }
}

// MARK: - MachineSize

struct MachineSize: Codable, Equatable, Hashable {
    var x: Double
    var y: Double
}

// MARK: - MachineCodeTemplate


struct MachineCommandItem: Codable, Identifiable, Hashable {
    var id = UUID()
    var command: String
    var description: String
}

// MARK: - MachineOption

struct MachineOption: Codable, Identifiable, Hashable {
    var id = UUID()
    var option: String
    var value: MachineOptionValue
    var description: String

    var valueAsString: String {
        get {
            switch value {
            case .bool(let boolVal):
                return boolVal ? "true" : "false"
            case .int(let intVal):
                return String(intVal)
            case .string(let strVal):
                return strVal
            }
        }
        set {
            if newValue.lowercased() == "true" {
                value = .bool(true)
            } else if newValue.lowercased() == "false" {
                value = .bool(false)
            } else if let intVal = Int(newValue) {
                value = .int(intVal)
            } else {
                value = .string(newValue)
            }
        }
    }
}

// MARK: - MachineOptionValue

enum MachineOptionValue: Codable, Hashable {
    case bool(Bool)
    case int(Int)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let strVal = try? container.decode(String.self) {
            self = .string(strVal)
        } else {
            throw DecodingError.typeMismatch(MachineOptionValue.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let boolVal):
            try container.encode(boolVal)
        case .int(let intVal):
            try container.encode(intVal)
        case .string(let strVal):
            try container.encode(strVal)
        }
    }
}


// MARK: - MachineConnection

struct MachineConnection: Codable, Equatable, Hashable {
    var connectionID: UUID?

    init(connectionID: UUID? = nil) {
        self.connectionID = connectionID
    }
}

// MARK: - MachineData

struct MachineData: Codable, Equatable, Identifiable, Hashable, ManageableItem, Defaultable {
    var id: UUID
    var name: String
    var description: String
    var typ: MachineType
    var size: MachineSize
    var commandProtocol: String
    var commandItems: [MachineCommandItem] // commands
    var penCount: Int
    var connection: MachineConnection
    var options: [MachineOption]

    var isConnected: Bool = false
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        typ: MachineType = .omnidirektionalPlotter,
        size: MachineSize = MachineSize(x: 0, y: 0),
        protokoll: String = "",
        commandItems: [MachineCommandItem] = [],
        penCount: Int = 1,
        connection: MachineConnection = MachineConnection(),
        options: [MachineOption] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.typ = typ
        self.size = size
        self.commandProtocol = protokoll
        self.commandItems = commandItems
        self.penCount = penCount
        self.connection = connection
        self.options = options
    }
    
    static var `default`: MachineData {
        MachineData(id: UUID.force("50529c2e-d9ae-42fa-a649-e1aa542a1a03"), name: "Keine Maschine")
    }

    static func == (lhs: MachineData, rhs: MachineData) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
