//
//  HatchFillManager.swift
//  Robart
//
//  Created by Carsten Nichte on 30.04.25.
//
// TODO: TODO-Markierungen (insbesondere im Contour-Following-Algorithmus) mit einem präziseren Offset-Berechner ersetzen.

//HatchFillManager.swift
import Foundation

/// Manager for applying hatch-fill algorithms to SVG files and generating output as SVG, GCode, and EggCode.
final class HatchFillManager {
    /// Types of hatch-fill algorithms supported.
    enum HatchType {
        case patternBased
        case contourFollowing
        case stippling
        case lineBased
        case gridBased
    }

    /// Applies a hatch-fill algorithm to an SVG file, writes a preview SVG, and returns GCode and EggCode.
    /// - Parameters:
    ///   - inputURL: URL of the source SVG file.
    ///   - hatchType: Hatch-fill algorithm to use.
    ///   - spacing: Spacing between hatch lines or points.
    ///   - svgSize: Tuple (width, height) of the SVG viewport.
    ///   - paperSize: Tuple (width, height) of the target paper for scaling.
    /// - Returns: (previewURL, gcodeLines, eggcodeLines)
    func process(inputURL: URL,
                 hatchType: HatchType,
                 spacing: Double = 5.0,
                 svgSize: (width: Double, height: Double),
                 paperSize: (width: Double, height: Double)) -> (previewURL: URL, gcode: [String], eggCode: [String]) {
        // 1. Parse original SVG elements
        let nullGen = BasePlotterGenerator()
        let svgParser = SVGParser(generator: nullGen)
        guard svgParser.loadSVGFile(from: inputURL,
                                    svgWidth: svgSize.width,
                                    svgHeight: svgSize.height,
                                    paperWidth: paperSize.width,
                                    paperHeight: paperSize.height) else {
            fatalError("Failed to load SVG file")
        }
        let elements = svgParser.elements.map { $0.element }

        // 2. Generate hatch paths for each element
        var hatchDs: [String] = []
        for element in elements {
            let lines = generateHatchLines(for: element, type: hatchType, spacing: spacing)
            for (p0, p1) in lines {
                let d = "M \(p0.x) \(p0.y) L \(p1.x) \(p1.y)"
                hatchDs.append(d)
            }
        }

        // 3. Build preview SVG content
        let svgContent = (try? String(contentsOf: inputURL)) ?? ""
        let pathElements = hatchDs.map { "<path d=\"\($0)\" stroke=\"black\" fill=\"none\"/>" }.joined(separator: "\n")
        let previewSVG = svgContent.replacingOccurrences(of: "</svg>", with: "\n<!-- Hatch preview -->\n\(pathElements)\n</svg>")

        // 4. Write preview file
        let previewURL = inputURL.deletingPathExtension()
            .appendingPathExtension("preview.svg")
        try? previewSVG.write(to: previewURL, atomically: true, encoding: .utf8)

        // 5. Generate GCode
        let gGen = GCodeGenerator()
        let gParser = SVGParser(generator: gGen)
        guard gParser.loadSVGFile(from: previewURL,
                                  svgWidth: svgSize.width,
                                  svgHeight: svgSize.height,
                                  paperWidth: paperSize.width,
                                  paperHeight: paperSize.height) else {
            fatalError("Failed to parse preview SVG for GCode")
        }
        let gcode = gParser.elements.map { $0.output }

        // 6. Generate EggCode
        let eGen = EggbotGenerator()
        let eParser = SVGParser(generator: eGen)
        guard eParser.loadSVGFile(from: previewURL,
                                  svgWidth: svgSize.width,
                                  svgHeight: svgSize.height,
                                  paperWidth: paperSize.width,
                                  paperHeight: paperSize.height) else {
            fatalError("Failed to parse preview SVG for EggCode")
        }
        let eggcode = eParser.elements.map { $0.output }

        return (previewURL, gcode, eggcode)
    }

    /// Generates hatch lines (segments) for a given SVG element.
    /// - Parameters:
    ///   - element: The SVG element to fill.
    ///   - type: Hatch-fill algorithm to use.
    ///   - spacing: Spacing parameter.
    /// - Returns: Array of line segments represented as ((x0,y0),(x1,y1)).
    private func generateHatchLines(for element: SVGElement,
                                    type: HatchType,
                                    spacing: Double) -> [((x: Double, y: Double), (x: Double, y: Double))] {
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

    // MARK: - Hatch Algorithms

    private func lineBasedHatch(for element: SVGElement, spacing: Double) -> [((Double, Double),(Double, Double))] {
        // Compute bounding box
        guard let xmin = element.attributes["x"], let ymin = element.attributes["y"],
              let width = element.attributes["width"], let height = element.attributes["height"]
        else { return [] }
        var lines: [((Double, Double),(Double, Double))] = []
        let maxY = ymin + height
        var y = ymin
        while y <= maxY {
            lines.append(((xmin, y), (xmin + width, y)))
            y += spacing
        }
        return lines
    }

    private func gridBasedHatch(for element: SVGElement, spacing: Double) -> [((Double, Double),(Double, Double))] {
        // Combines horizontal and vertical lines
        var lines = lineBasedHatch(for: element, spacing: spacing)
        guard let xmin = element.attributes["x"], let ymin = element.attributes["y"],
              let width = element.attributes["width"], let height = element.attributes["height"]
        else { return lines }
        let maxX = xmin + width
        var x = xmin
        while x <= maxX {
            lines.append(((x, ymin), (x, ymin + height)))
            x += spacing
        }
        return lines
    }

    private func patternBasedHatch(for element: SVGElement, spacing: Double) -> [((Double, Double),(Double, Double))] {
        // Diagonal + crosshatch
        var lines: [((Double, Double),(Double, Double))] = []
        // Use line-based as base
        lines += lineBasedHatch(for: element, spacing: spacing)
        // Diagonal / lines
        guard let xmin = element.attributes["x"], let ymin = element.attributes["y"],
              let width = element.attributes["width"], let height = element.attributes["height"]
        else { return lines }
        let diagCount = Int((width + height) / spacing)
        for i in 0...diagCount {
            let start = (xmin + Double(i) * spacing, ymin)
            let end = (xmin, ymin + Double(i) * spacing)
            lines.append((start, end))
        }
        return lines
    }

    private func contourFollowingHatch(for element: SVGElement, spacing: Double) -> [((Double, Double),(Double, Double))] {
        // Placeholder: offset contours inside object
        // TODO: implement proper contour offsets along shape path
        return lineBasedHatch(for: element, spacing: spacing / 2)
    }

    private func stipplingHatch(for element: SVGElement, density: Double) -> [((Double, Double),(Double, Double))] {
        // Generate point-dot stippling as very short lines
        var points: [((Double, Double),(Double, Double))] = []
        guard let xmin = element.attributes["x"], let ymin = element.attributes["y"],
              let width = element.attributes["width"], let height = element.attributes["height"]
        else { return [] }
        let count = Int((width * height) / (density * density))
        for _ in 0..<count {
            let x = xmin + Double.random(in: 0...width)
            let y = ymin + Double.random(in: 0...height)
            let r = density / 10.0
            points.append(((x - r, y - r), (x + r, y + r)))
        }
        return points
    }
}
