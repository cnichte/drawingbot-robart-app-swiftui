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
     appLog(.info, "GCode für Kreis:\n\(circleItem.output)")
 }

 z. B. das erste Element ausgeben
 if let first = elements.first {
     appLog(.info, "GCode für \(first.element.name):\n\(first.output)")
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

import Foundation

/// A structure representing an SVG element with identifiable and hashable properties.
struct SVGElement: Identifiable, Hashable {
    /// A unique identifier for the SVG element.
    let id: UUID
    
    /// The name of the SVG element (e.g., "rect", "circle").
    let name: String
    
    /// A dictionary of attributes with numeric values (e.g., "x", "y", "width").
    let attributes: [String: Double]
    
    /// A dictionary of raw attributes as strings (e.g., "d" for paths, "points" for polylines).
    let rawAttributes: [String: String]
    
    /// Compares two SVG elements for equality based on their IDs.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand SVG element.
    ///   - rhs: The right-hand SVG element.
    /// - Returns: `true` if the elements have the same ID, `false` otherwise.
    static func == (lhs: SVGElement, rhs: SVGElement) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Hashes the SVG element into a hasher.
    ///
    /// Combines the `id`, `name`, and `attributes` into the hasher for uniqueness.
    ///
    /// - Parameter hasher: The hasher to combine values into.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(attributes)
    }
    
    /// Accesses a numeric attribute by key.
    ///
    /// - Parameter key: The attribute key (e.g., "x", "y").
    /// - Returns: The `Double` value of the attribute, or `nil` if not found.
    subscript(key: String) -> Double? {
        return attributes[key]
    }
}

/// A structure representing a parsed SVG element with its generated output.
struct ParserListItem: Identifiable, Hashable {
    /// The unique identifier of the associated SVG element.
    var id: UUID { element.id }
    
    /// The SVG element associated with this item.
    let element: SVGElement
    
    /// The generated output string for the SVG element.
    let output: String
    
    /// Compares two parser list items for equality based on their IDs.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand parser list item.
    ///   - rhs: The right-hand parser list item.
    /// - Returns: `true` if the items have the same ID, `false` otherwise.
    static func == (lhs: ParserListItem, rhs: ParserListItem) -> Bool {
        lhs.id == rhs.id
    }
    
    /// Hashes the parser list item into a hasher.
    ///
    /// Combines the `id`, `element`, and `output` into the hasher for uniqueness.
    ///
    /// - Parameter hasher: The hasher to combine values into.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(element)
        hasher.combine(output)
    }
}

// MARK: - Generator Protocol

/// A protocol defining the interface for generating code from SVG elements.
protocol PlotterCodeGenerator {
    /// Generates a string representation for a given SVG element.
    ///
    /// - Parameter element: The SVG element to generate code for.
    /// - Returns: A string containing the generated code.
    func generate(for element: SVGElement) -> String
}

// MARK: - Generic SVG Parser

/// A generic SVG parser that processes SVG files and generates output using a provided code generator.
class SVGParser<Generator: PlotterCodeGenerator>: NSObject, XMLParserDelegate {
    /// The code generator used to produce output for parsed SVG elements.
    private let generator: Generator
    
    /// The XML parser used to process the SVG file.
    private var parser: XMLParser?
    
    /// The list of parsed SVG elements and their generated outputs.
    private(set) var elements: [ParserListItem] = []
    
    /// A stack of transformation offsets (dx, dy) for handling nested group transformations.
    private var transformStack: [(dx: Double, dy: Double)] = [(0, 0)]
    
    /// The scaling factor for the x-axis based on paper and SVG dimensions.
    private var scaleX: Double = 1.0
    
    /// The scaling factor for the y-axis based on paper and SVG dimensions.
    private var scaleY: Double = 1.0
    
    /// Initializes the parser with a code generator.
    ///
    /// - Parameter generator: The generator used to produce output for SVG elements.
    init(generator: Generator) {
        self.generator = generator
    }
    
    /// Loads and parses an SVG file, scaling it to fit the specified paper dimensions.
    ///
    /// - Parameters:
    ///   - fileURL: The URL of the SVG file to load.
    ///   - svgWidth: The width of the SVG viewport.
    ///   - svgHeight: The height of the SVG viewport.
    ///   - paperWidth: The target paper width for scaling.
    ///   - paperHeight: The target paper height for scaling.
    /// - Returns: `true` if the file was successfully parsed, `false` otherwise.
    func loadSVGFile(from fileURL: URL, svgWidth: Double, svgHeight: Double, paperWidth: Double, paperHeight: Double) -> Bool {
        scaleX = paperWidth / svgWidth
        scaleY = paperHeight / svgHeight
        
        do {
            let data = try Data(contentsOf: fileURL)
            parser = XMLParser(data: data)
            parser?.delegate = self
            return parser?.parse() ?? false
        } catch {
            appLog(.info, "Fehler beim Laden der Datei: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Returns the current transformation offset (dx, dy).
    ///
    /// - Returns: A tuple containing the current translation offsets.
    func currentTransform() -> (dx: Double, dy: Double) {
        return transformStack.last ?? (0, 0)
    }
    
    /// Applies the current transformation to a point (x, y).
    ///
    /// - Parameters:
    ///   - x: The x-coordinate to transform.
    ///   - y: The y-coordinate to transform.
    /// - Returns: A tuple containing the transformed (x, y) coordinates.
    func applyTransform(x: Double, y: Double) -> (Double, Double) {
        let t = currentTransform()
        return (x + t.dx, y + t.dy)
    }
    
    /// Called when the XML parser encounters the start of an element.
    ///
    /// Processes SVG elements, applies transformations, and generates output using the code generator.
    ///
    /// - Parameters:
    ///   - parser: The XML parser processing the SVG file.
    ///   - elementName: The name of the element (e.g., "rect", "g").
    ///   - namespaceURI: The namespace URI, if any.
    ///   - qName: The qualified name of the element.
    ///   - attributeDict: A dictionary of the element's attributes.
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
 
        /* TODO: Neuer Pattern Support / Experimentell
        // ########## neuer pattern support - start
        // Pattern-Elemente zuerst erfassen
        // Hier müsste eine Instanz von SVGPatternElementParser vorgeladen werden
        // ...

        // Normale Elemente verarbeiten
        // (Original-Code aus SVGParser)
        // Erstelle SVGElement und generiere Basis-Output
        
        
        // Normale Elemente verarbeiten
        // (Original-Code aus SVGParser)
        // Erstelle SVGElement und generiere Basis-Output
        let attrsNum = parseNumericAttributes(attributeDict)
        let element = SVGElement(id: UUID(), name: elementName,
                                 attributes: attrsNum,
                                 rawAttributes: attributeDict)
        let baseOutput = generator.generate(for: element)
        elements.append(ParserListItem(element: element, output: baseOutput))

        // Pattern-Fill anwenden (falls relevant)
        if let patternParser = self.patternParser {
            let extra = patternParser.applyPatternIfNeeded(to: element)
            elements.append(contentsOf: extra)
        }
        // ########## neuer pattern support - ende
*/
        
        // ----- originalcode
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
        
        // Handle special attributes (e.g., "points", "d") by preserving their raw values
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
    
    /// Called when the XML parser encounters the end of an element.
    ///
    /// Pops the transformation stack for group (`g`) elements.
    ///
    /// - Parameters:
    ///   - parser: The XML parser processing the SVG file.
    ///   - elementName: The name of the element.
    ///   - namespaceURI: The namespace URI, if any.
    ///   - qName: The qualified name of the element.
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "g" {
            _ = transformStack.popLast()
        }
    }
    
    
    /// Beispiel-Helfer zum Parsen numerischer Attribute.
    private func parseNumericAttributes(_ dict: [String:String]) -> [String: Double] {
        var result: [String:Double] = [:]
        for (k,v) in dict {
            if let d = Double(v) { result[k] = d }
        }
        return result
    }
    
    /// Property für den Pattern-Parser (vom Aufrufer zu setzen).
    var patternParser: SVGPatternElementParser? {
        // muss extern initialisiert werden
        return nil
    }
}
