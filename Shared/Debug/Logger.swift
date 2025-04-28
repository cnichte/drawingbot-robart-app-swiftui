//
//  Logger.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// TODO: Beim App-Start alte Logs löschen oder behalten.
// TODO: Maximalgröße prüfen und rotieren (Logfile zu groß? -> Neue Datei anlegen).
// TODO: Crash-Logs mitschreiben.
// TODO: Später Log-Level (Info, Warnung, Fehler) einführen.

// Logger.swift

import Foundation
import SwiftUI

enum LogLevel: String, Codable, CaseIterable {
    case verbose, info, warning, error
}

func appLog(_ level: LogLevel = .info, _ items: Any..., separator: String = " ", terminator: String = "\n") {
    Logger.shared.log(level: level, items, separator: separator, terminator: terminator)
}

class Logger: ObservableObject {
    static let shared = Logger()

    // Globaler Log-Level, standardmäßig 'verbose'
    @AppStorage("logLevel") private var debugLevel: LogLevel = .verbose
    @AppStorage("loggingEnabled") private var loggingEnabled: Bool = true

    private var logFileURL: URL?

    private init() {
        setupLogFile()
    }

    private func setupLogFile() {
        do {
            let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let logFile = documents.appendingPathComponent("app-log.txt")
            self.logFileURL = logFile
            try? "".write(to: logFile, atomically: true, encoding: .utf8)
            print("📝 Logger initialisiert: \(logFile.path)")
        } catch {
            print("❌ Fehler beim Einrichten der Log-Datei: \(error.localizedDescription)")
        }
    }
    
    func log(level: LogLevel? = nil, _ items: Any..., separator: String = " ", terminator: String = "\n") {
        guard loggingEnabled else { return }

        let effectiveLevel = level ?? debugLevel

        if shouldLog(effectiveLevel) {
            let message = items.map { "\($0)" }.joined(separator: separator)
            Swift.print(message, terminator: terminator)

            guard let url = logFileURL else { return }

            let timestamp = ISO8601DateFormatter().string(from: Date())
            let fullMessage = "[\(timestamp)] [\(effectiveLevel.rawValue.uppercased())] \(message)\n"

            do {
                let handle = try FileHandle(forWritingTo: url)
                handle.seekToEndOfFile()
                if let data = fullMessage.data(using: .utf8) {
                    handle.write(data)
                }
                try handle.close()
            } catch {
                Swift.print("⚠️ Fehler beim Schreiben in Log-Datei: \(error)")
            }
        }
    }

    private func shouldLog(_ level: LogLevel) -> Bool {
        switch debugLevel {
        case .verbose:
            return true
        case .info:
            return level != .verbose
        case .warning:
            return level == .warning || level == .error
        case .error:
            return level == .error
        }
    }
}
