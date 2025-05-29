//
//  SVGParser+PatternSupport.swift
//  Robart
//
//  Created by Carsten Nichte on 30.04.25.
//

// SVGParser+PatternSupport.swift
import Foundation

/// Parser für <pattern>-Elemente und automatische Anwendung von HatchFillManager.
final class SVGPatternElementParser: NSObject, XMLParserDelegate {
    /// Gesammelte Pattern-Definitionen nach ID.
    private var patterns: [String: [SVGElement]] = [:]
    private var currentPatternID: String?
    private var currentElements: [SVGElement] = []
    private let hatchManager: HatchFillManager
    private let defaultType: HatchFillManager.HatchType
    private let defaultSpacing: Double

    /// Initialisiert den Pattern-Parser.
    init(hatchManager: HatchFillManager,
         defaultType: HatchFillManager.HatchType = .lineBased,
         defaultSpacing: Double = 5.0) {
        self.hatchManager = hatchManager
        self.defaultType = defaultType
        self.defaultSpacing = defaultSpacing
    }

    // MARK: Parser für <pattern>

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String]) {
        if elementName == "pattern", let id = attributeDict["id"] {
            currentPatternID = id
            currentElements = []
            return
        }
        guard currentPatternID != nil else { return }
        // Sammle jedes Kind als SVGElement
        var attrs: [String: Double] = [:]
        for (k,v) in attributeDict { if let d = Double(v) { attrs[k] = d } }
        let svgEl = SVGElement(id: UUID(), name: elementName,
                               attributes: attrs,
                               rawAttributes: attributeDict)
        currentElements.append(svgEl)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "pattern", let pid = currentPatternID {
            patterns[pid] = currentElements
            currentPatternID = nil
        }
    }

    /// Prüft, ob ein Element ein Pattern-Fill nutzt, und generiert Hatch-Linien.
    func applyPatternIfNeeded(to element: SVGElement) -> [ParserListItem] {
        guard let fill = element.rawAttributes["fill"],
              fill.hasPrefix("url(#"),
              let start = fill.firstIndex(of: "#"),
              let end = fill.firstIndex(of: ")")
        else { return [] }
        let pid = String(fill[fill.index(after: start)..<end])
        guard patterns[pid] != nil else { return [] }

        // Erstelle ParserListItem für Original
        var items: [ParserListItem] = []
        items.append(ParserListItem(element: element,
                                     output: "; Pattern-\(pid) angewendet"))
        // Generiere Hatch-Pfade
        let segments = hatchManager.generateHatchLines(for: element,
                                                       type: defaultType,
                                                       spacing: defaultSpacing)
        for (p0,p1) in segments {
            let d = "M \(p0.x) \(p0.y) L \(p1.x) \(p1.y)"
            let pathEl = SVGElement(id: UUID(), name: "path",
                                     attributes: [:],
                                     rawAttributes: ["d": d])
            items.append(ParserListItem(element: pathEl, output: d))
        }
        return items
    }
}
