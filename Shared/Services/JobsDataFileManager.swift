//
//  SVGFileManager.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// SVGFileManager.swift
import Foundation

class SVGFileManager {
    static let shared = SVGFileManager()
    
    private let fileManager = FileManager.default
    private let baseDirectory: URL
    
    private init() {
        do {
            self.baseDirectory = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("svgs")
        } catch {
            fatalError("❌ Konnte Documents-Verzeichnis nicht laden: \(error)")
        }
    }
    
    func deleteSVGAndSidecars(named filename: String) {
        let baseName = (filename as NSString).deletingPathExtension
        let extensions = ["svg", "json", "gcode", "egg"] // Erweiterbar
        
        for ext in extensions {
            let fileURL = baseDirectory.appendingPathComponent("\(baseName).\(ext)")
            if fileManager.fileExists(atPath: fileURL.path) {
                do {
                    try fileManager.removeItem(at: fileURL)
                    appLog("🗑️ Gelöscht: \(fileURL.lastPathComponent)")
                } catch {
                    appLog("❌ Fehler beim Löschen von \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }
    }
}
