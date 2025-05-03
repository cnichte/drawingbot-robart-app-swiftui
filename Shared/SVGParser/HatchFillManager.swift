//
//  HatchFillManager.swift
//  Robart
//
//  Created by Carsten Nichte on 30.04.25.
//
// TODO: TODO-Markierungen (insbesondere im Contour-Following-Algorithmus) mit einem präziseren Offset-Berechner ersetzen.

//HatchFillManager.swift
import Foundation

/// Manager für Hatch-Fill-Algorithmen auf SVG-Elementen.
///
/// Lädt eine SVG-Datei, wendet ein Hatch-Muster an, speichert eine Vorschau-SVG
/// und liefert GCode- und EggCode-Strings zurück.
final class HatchFillManager {
    
    private var machineData: MachineData
    
    init(machineData: MachineData) {
        self.machineData = machineData
    }
    
    /// Unterstützte Hatch-Fülltypen.
    enum HatchType {
        case patternBased
        case contourFollowing
        case stippling
        case lineBased
        case gridBased
    }

    /// Verarbeitet eine SVG-Datei mit dem gegebenen Hatch-Algorithmus.
    ///
    /// - Parameters:
    ///   - inputURL: URL zur Quelldatei (.svg).
    ///   - hatchType: Ausgewählter Muster-Typ.
    ///   - spacing: Abstand zwischen Linien oder Punktpaaren.
    ///   - svgSize: SVG-Viewport-Größe (width, height).
    ///   - paperSize: Ziel-Papiermaße (width, height) für Skalierung.
    /// - Returns: Tuple mit
    ///   - previewURL: URL zur generierten Vorschau-SVG.
    ///   - gcode: Array von GCode-Zeilen.
    ///   - eggCode: Array von EggCode-Zeilen.
    func process(inputURL: URL,
                 hatchType: HatchType,
                 spacing: Double = 5.0,
                 svgSize: (width: Double, height: Double),
                 paperSize: (width: Double, height: Double)) -> (previewURL: URL, gcode: [String], eggCode: [String]) {
        // 1. Original-SVG parsen ohne Code-Generierung
        let nullGen = BasePlotterGenerator()
        let svgParser = SVGParser(generator: nullGen)
        guard svgParser.loadSVGFile(from: inputURL,
                                    svgWidth: svgSize.width,
                                    svgHeight: svgSize.height,
                                    paperWidth: paperSize.width,
                                    paperHeight: paperSize.height)
        else { fatalError("Fehler beim Laden der SVG-Datei") }
        let elements = svgParser.elements.map { $0.element }

        // 2. Hatch-Linien berechnen
        var hatchDs: [String] = []
        for element in elements {
            let segments = generateHatchLines(for: element, type: hatchType, spacing: spacing)
            for (p0, p1) in segments {
                hatchDs.append("M \(p0.x) \(p0.y) L \(p1.x) \(p1.y)")
            }
        }

        // 3. Vorschau-SVG erzeugen
        let originalSVG = (try? String(contentsOf: inputURL)) ?? ""
        let pathTags = hatchDs.map { "<path d='\($0)' stroke='black' fill='none'/>" }.joined(separator: "\n")
        let previewContent = originalSVG.replacingOccurrences(of: "</svg>",
            with: "\n<!-- Hatch-Fill Vorschau -->\n\(pathTags)\n</svg>")
        let previewURL = inputURL.deletingPathExtension().appendingPathExtension("preview.svg")
        try? previewContent.write(to: previewURL, atomically: true, encoding: .utf8)

        // 4. GCode generieren
        let gGen = GCodeGenerator(machineData: machineData)
        let gParser = SVGParser(generator: gGen)
        guard gParser.loadSVGFile(from: previewURL,
                                  svgWidth: svgSize.width,
                                  svgHeight: svgSize.height,
                                  paperWidth: paperSize.width,
                                  paperHeight: paperSize.height)
        else { fatalError("Fehler beim Parsen der Vorschau für GCode") }
        let gcode = gParser.elements.map { $0.output }

        // 5. EggCode generieren
        let eGen = EggbotGenerator(machineData: machineData)
        let eParser = SVGParser(generator: eGen)
        guard eParser.loadSVGFile(from: previewURL,
                                  svgWidth: svgSize.width,
                                  svgHeight: svgSize.height,
                                  paperWidth: paperSize.width,
                                  paperHeight: paperSize.height)
        else { fatalError("Fehler beim Parsen der Vorschau für EggCode") }
        let eggcode = eParser.elements.map { $0.output }

        return (previewURL, gcode, eggcode)
    }

    /// Leitet auf den gewünschten Hatch-Algorithmus weiter.
    public func generateHatchLines(for element: SVGElement,
                                    type: HatchType,
                                    spacing: Double) -> [((x: Double, y: Double),(x: Double, y: Double))] {
        switch type {
        case .lineBased:
            return lineBasedHatch(for: element, spacing: spacing)
        case .gridBased:
            return gridBasedHatch(for: element, spacing: spacing)
        case .patternBased:
            return patternBasedHatch(for: element, spacing: spacing)
        case .contourFollowing:
            return contourFollowingHatch(for: element, spacing: spacing)
        case .stippling:
            return stipplingHatch(for: element, density: spacing)
        }
    }

    // MARK: - Algorithmen

    public func lineBasedHatch(for element: SVGElement, spacing: Double) -> [((Double, Double),(Double, Double))] {
        guard let x = element.attributes["x"], let y = element.attributes["y"],
              let w = element.attributes["width"], let h = element.attributes["height"]
        else { return [] }
        var lines: [((Double, Double),(Double, Double))] = []
        var yy = y
        while yy <= y + h {
            lines.append(((x, yy), (x + w, yy)))
            yy += spacing
        }
        return lines
    }

    public func gridBasedHatch(for element: SVGElement, spacing: Double) -> [((Double, Double),(Double, Double))] {
        var lines = lineBasedHatch(for: element, spacing: spacing)
        guard let x = element.attributes["x"], let y = element.attributes["y"],
              let w = element.attributes["width"], let h = element.attributes["height"]
        else { return lines }
        var xx = x
        while xx <= x + w {
            lines.append(((xx, y), (xx, y + h)))
            xx += spacing
        }
        return lines
    }

    private func patternBasedHatch(for element: SVGElement, spacing: Double) -> [((Double, Double),(Double, Double))] {
        var lines = lineBasedHatch(for: element, spacing: spacing)
        guard let x = element.attributes["x"], let y = element.attributes["y"],
              let w = element.attributes["width"], let h = element.attributes["height"]
        else { return lines }
        let count = Int((w + h) / spacing)
        for i in 0...count {
            let start = (x + Double(i)*spacing, y)
            let end = (x, y + Double(i)*spacing)
            lines.append((start, end))
        }
        return lines
    }

    private func contourFollowingHatch(for element: SVGElement, spacing: Double) -> [((Double, Double),(Double, Double))] {
        var lines: [((Double, Double),(Double, Double))] = []
        guard let x = element.attributes["x"], let y = element.attributes["y"],
              let w = element.attributes["width"], let h = element.attributes["height"]
        else { return [] }
        var inset: Double = 0
        while inset <= min(w/2, h/2) {
            let xmin = x + inset, ymin = y + inset
            let width = w - 2*inset, height = h - 2*inset
            // 4 Kanten
            lines.append(((xmin, ymin), (xmin+width, ymin)))
            lines.append(((xmin+width, ymin), (xmin+width, ymin+height)))
            lines.append(((xmin+width, ymin+height), (xmin, ymin+height)))
            lines.append(((xmin, ymin+height), (xmin, ymin)))
            inset += spacing
        }
        return lines
    }

    private func stipplingHatch(for element: SVGElement, density: Double) -> [((Double, Double),(Double, Double))] {
        var points: [((Double, Double),(Double, Double))] = []
        guard let x = element.attributes["x"], let y = element.attributes["y"],
              let w = element.attributes["width"], let h = element.attributes["height"]
        else { return [] }
        let count = Int((w * h) / (density * density))
        for _ in 0..<count {
            let px = x + Double.random(in: 0...w)
            let py = y + Double.random(in: 0...h)
            let r = density / 10
            points.append(((px-r, py-r), (px+r, py+r)))
        }
        return points
    }
}
