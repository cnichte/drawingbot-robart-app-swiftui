//
//  SVGtoGCodeParser.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 14.04.25.
//
// rect, circle, line, path (M/L), ellipse, polyline, Bezier-Kurven (C, Q)

// Da du bei path keine numerischen Attribute nutzt, kannst du ein Dummy-Attribut setzen, oder SVGElement optional so erweitern, dass es String-basierte Attribute erlaubt. Wenn du später auch komplexere Pfade (C, Q, A, usw.) willst, wäre das der nächste Schritt.

// Bezier-Kurven (C, Q)
// relative Bewegungen (m, l).
// polygon, text, transform="...", oder echte Kreisbögen mit G2/G3
// Wenn du eine präzisere Ellipsenbogen-Berechnung oder Unterstützung für G2/G3 (Kreisinterpolation) willst, sag einfach Bescheid – ich helfe dir gern beim Upgrade!

// TODO: ??
// relative Befehle (m, l, c, q)?
// A (Elliptischer Bogen)?
// oder polygon?
// die Polygon-Schließung korrekt implementieren?
// G2/G3 für echte Bögen verwenden?
// eine Vorschau/Simulation im SwiftUI-Frontend?

// TODO: !!
// den SVG-Parser robuster machen (z. B. Koordinatenlisten analysieren)
// SwiftUI-Vorschau für Pfade und GCode generieren
// GCode direkt an den Plotter schicken?

// scale, rotate in transform unterstützen?
// oder GCode exportierbar machen (z. B. als Datei im SwiftUI-Frontend)?

//  mit rotate, scale, Text oder Gradient).

// TODO: Optimierung kürzester Fahrweg.
// TODO: Beschreibung zu G-Code
// TODO: G-Code-Templates auslagern in settings? -> modifizierbar machen.
// TODO: Tatsächliche Papiergröße berücksichtigen
// TODO: Move zoom und rotate vom Preview  berücksichtigen.
// TODO: SVG-Ebenen ausblenden -> Svg Code ausblenden.
// TODO: Stift für GCodeGenerator !!

/*
 
 Erweiterungen geplant / möglich
     •    Unterstützung für H, V, T, S im PathParser
     •    Style-/Füllattribute analysieren
     •    Vorschau-Rendering direkt aus SVGElement-Daten (SwiftUI)
     •    Undo/Redo-System mit Element-Änderungen
 */
/*
 
 let parser = SVGParser(generator: GCodeGenerator())
 let success = parser.loadSVGFile(from: svgFileURL, svgWidth: 600, svgHeight: 600, paperWidth: 600, paperHeight: 600)
 let elements = parser.elements
 
 1. Alle GCode-Ausgaben auflisten
 
 for item in parser.elements {
     print(item.output)
 }
 
Oder als ein einzelner Block GCode:
 
 let fullGCode = elements.map { $0.output }.joined(separator: "\n")
 print(fullGCode)
 
 2. GCode für ein bestimmtes SVG-Element ausgeben:
 
 Zum Beispiel: Den GCode des ersten Kreiselements finden:
 if let circleItem = parser.elements.first(where: { $0.element.name == "circle" }) {
     print("GCode für Kreis:\n\(circleItem.output)")
 }

 z. B. das erste Element ausgeben
 if let first = elements.first {
     print("GCode für \(first.element.name):\n\(first.output)")
 }
 
 Oder falls du den GCode zu einem bestimmten SVGElement hast:
 
 func gCode(for element: SVGElement) -> String? {
     return parser.elements.first(where: { $0.element.id == element.id })?.output
 }
 

 
 3. Parser mehrfach verwenden
 Da der Parser generisch ist, kannst man einfach einen anderen Generator übergeben:
 
 let eggParser = SVGParser(generator: EggbotGenerator())
 let success = parser.loadSVGFile(from: svgFileURL, svgWidth: 600, svgHeight: 600, paperWidth: 600, paperHeight: 600)
 let eggCode = eggParser.elements.map { $0.output }.joined(separator: "\n")
 
 */


// SVGParser.swift
import Foundation

// MARK: - SVGElement & ParserListItem

struct SVGElement: Identifiable, Hashable {
    let id: UUID
    let name: String
    let attributes: [String: Double]
    let rawAttributes: [String: String] // für z. B. d, points

    static func == (lhs: SVGElement, rhs: SVGElement) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(attributes)
    }
    
    subscript(key: String) -> Double? {
            return attributes[key]
        }
}

struct ParserListItem: Identifiable, Hashable {
    var id: UUID { element.id }
    let element: SVGElement
    let output: String

    static func == (lhs: ParserListItem, rhs: ParserListItem) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(element)
        hasher.combine(output)
    }
}

// MARK: - Generator-Protokoll

protocol PlotterCodeGenerator {
    func generate(for element: SVGElement) -> String
}

// MARK: - Generischer SVG-Parser

class SVGParser<Generator: PlotterCodeGenerator>: NSObject, XMLParserDelegate {
    private let generator: Generator
    private var parser: XMLParser?
    private(set) var elements: [ParserListItem] = []

    private var transformStack: [(dx: Double, dy: Double)] = [(0, 0)]
    private var scaleX: Double = 1.0
    private var scaleY: Double = 1.0

    init(generator: Generator) {
        self.generator = generator
    }

    func loadSVGFile(from fileURL: URL, svgWidth: Double, svgHeight: Double, paperWidth: Double, paperHeight: Double) -> Bool {
        scaleX = paperWidth / svgWidth
        scaleY = paperHeight / svgHeight

        do {
            let data = try Data(contentsOf: fileURL)
            parser = XMLParser(data: data)
            parser?.delegate = self
            return parser?.parse() ?? false
        } catch {
            print("Fehler beim Laden der Datei: \(error.localizedDescription)")
            return false
        }
    }

    func currentTransform() -> (dx: Double, dy: Double) {
        return transformStack.last ?? (0, 0)
    }

    func applyTransform(x: Double, y: Double) -> (Double, Double) {
        let t = currentTransform()
        return (x + t.dx, y + t.dy)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {

        if elementName == "g" {
            if let transform = attributeDict["transform"],
               transform.starts(with: "translate("),
               let open = transform.range(of: "translate(")?.upperBound,
               let close = transform.range(of: ")")?.lowerBound {

                let values = transform[open..<close]
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .compactMap(Double.init)

                let dx = (values.count > 0 ? values[0] : 0.0) * scaleX
                let dy = (values.count > 1 ? values[1] : 0.0) * scaleY
                let parent = currentTransform()
                transformStack.append((parent.dx + dx, parent.dy + dy))
            } else {
                transformStack.append(currentTransform())
            }
            return
        }

        var attributes: [String: Double] = [:]
        for (key, value) in attributeDict {
            if let val = Double(value) {
                switch key {
                case "x", "cx", "x1", "x2":
                    attributes[key] = applyTransform(x: val * scaleX, y: 0).0
                case "y", "cy", "y1", "y2":
                    attributes[key] = applyTransform(x: 0, y: val * scaleY).1
                case "width", "rx":
                    attributes[key] = val * scaleX
                case "height", "ry":
                    attributes[key] = val * scaleY
                case "r":
                    attributes[key] = val * ((scaleX + scaleY) / 2)
                default:
                    break
                }
            }
        }

        // Für spezielle Felder original übernehmen
        if let points = attributeDict["points"] {
            attributes["points_raw"] = 1 // Marker
            let element = SVGElement(id: UUID(), name: elementName, attributes: attributes, rawAttributes: ["points": points])
            let output = generator.generate(for: element)
            elements.append(ParserListItem(element: element, output: output))
            return
        }
        if let d = attributeDict["d"] {
            attributes["d_raw"] = 1
            let element = SVGElement(id: UUID(), name: elementName, attributes: attributes, rawAttributes: ["d": d])
            let output = generator.generate(for: element)
            elements.append(ParserListItem(element: element, output: output))
            return
        }

        let element = SVGElement(id: UUID(), name: elementName, attributes: attributes, rawAttributes: attributeDict)
        let output = generator.generate(for: element)
        elements.append(ParserListItem(element: element, output: output))
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "g" {
            _ = transformStack.popLast()
        }
    }
}
