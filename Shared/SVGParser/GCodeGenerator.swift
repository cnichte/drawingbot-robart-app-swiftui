//
//  GCodeGenerator.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

/*
 "commandItems":[
    { "0446c01b-1c47-4ab4-a4e4-68fa00ad9c41": "auto", "name": "PEN_UP",    "command": "M5",           "description": "Stift anheben" },
    { "a7a1e0a3-2d1f-4c20-b47d-519ac3055c49": "auto", "name": "PEN_DOWN",  "command": "M3 S90",       "description": "Stift absenken" },
    { "c0f87284-58df-4656-b9b3-31900fe246f8": "auto", "name": "MOVE_FAST", "command": "G0 X{X} Y{Y}", "description": "Schnellpositionierung" },
    { "787b2faa-c2c0-4963-8fcc-e5c26e9b5737": "auto", "name": "DRAW_LINE", "command": "G1 X{X} Y{Y}", "description": "Linienbewegung" }
 */

// GCodeGenerator.swift
import Foundation

/// A class that generates G-code for SVG elements, extending `BasePlotterGenerator`.
final class GCodeGenerator: BasePlotterGenerator {
    
    /// Resolver für GCode-Templates aus MachineData.commandItems
    private let resolver: MachineCommandResolver

    /// Initialisiert den Generator mit einem Template-Resolver basierend auf den Maschinenbefehlen
    init(machineData: MachineData) {
        self.resolver = MachineCommandResolver(commandItems: machineData.commandItems)
    }

    /// Liefert einen GCode-Befehl durch Ersetzung von Platzhaltern im Template
    private func cmd(_ name: String, x: Double, y: Double) -> String {
        resolver.resolve(name: name, variables: ["X": x, "Y": y]) ?? "; fehlend: \(name)"
    }

    /// Generates G-code for a given SVG element based on its type.
    ///
    /// Supports SVG elements such as rectangles, circles, lines, ellipses, polylines, polygons, and paths.
    ///
    /// - Parameter e: The SVG element to generate G-code for.
    /// - Returns: A string containing the G-code representation of the element, or a comment if unsupported.
    override func generate(for e: SVGElement) -> String {
        switch e.name {
        case "rect": return generateRect(from: e)
        case "circle": return generateCircle(from: e)
        case "line": return generateLine(from: e)
        case "ellipse": return generateEllipse(from: e)
        case "polyline": return generatePolyline(from: e, close: false)
        case "polygon": return generatePolyline(from: e, close: true)
        case "path": return parsePath(e)
        default: return "; \(e.name) nicht unterstützt"
        }
    }

    /// Parses an SVG path element and generates G-code for its commands.
    ///
    /// Uses `PathParser` to process the path's `d` attribute and generates G-code for supported commands (e.g., MoveTo, LineTo, Cubic Bezier, Quadratic Bezier, Arc, ClosePath).
    ///
    /// - Parameter e: The SVG path element.
    /// - Returns: A string containing the G-code for the path, or a comment if the path is invalid.
    private func parsePath(_ e: SVGElement) -> String {
        guard let d = e.rawAttributes["d"] else { return "; Pfad fehlt" }
        var g = ""
        var x = 0.0, y = 0.0
        var start = (0.0, 0.0)

        let parser = PathParser(d: d) { cmd, points, isRel in
            switch cmd {
            case "M":
                let p = self.transform(points[0], points[1]); start = p; x = p.0; y = p.1
                g += self.cmd("MOVE_FAST", x: x, y: y) + "\n"
            case "L":
                let p = self.transform(points[0], points[1]); x = p.0; y = p.1
                g += self.cmd("DRAW_LINE", x: x, y: y) + "\n"
            case "C":
                let p0 = (x, y)
                let c1 = self.transform(points[0], points[1])
                let c2 = self.transform(points[2], points[3])
                let to = self.transform(points[4], points[5])
                for pt in Math.cubicBezier(from: p0, c1: c1, c2: c2, to: to) {
                    g += self.cmd("DRAW_LINE", x: pt.0, y: pt.1) + "\n"
                }
                x = to.0; y = to.1
            case "Q":
                let p0 = (x, y)
                let ctrl = self.transform(points[0], points[1])
                let to = self.transform(points[2], points[3])
                for pt in Math.quadraticBezier(from: p0, control: ctrl, to: to) {
                    g += self.cmd("DRAW_LINE", x: pt.0, y: pt.1) + "\n"
                }
                x = to.0; y = to.1
            case "A":
                let to = self.transform(points[5], points[6])
                let arcPoints = PathParser.arcApprox(
                    from: (x, y), to: to,
                    rx: points[0], ry: points[1],
                    xAxisRotation: points[2],
                    largeArc: points[3] != 0,
                    sweep: points[4] != 0
                )
                for pt in arcPoints.dropFirst() {
                    g += self.cmd("DRAW_LINE", x: pt.0, y: pt.1) + "\n"
                }
                x = to.0; y = to.1
            case "Z":
                g += self.cmd("DRAW_LINE", x: start.0, y: start.1) + "\n"
                x = start.0; y = start.1
            default: break
            }
        }
        parser.parse()
        return g
    }

    /// Generates G-code for an SVG rectangle element.
    ///
    /// Creates a closed path around the rectangle's perimeter using G0 (move) and G1 (line) commands.
    private func generateRect(from e: SVGElement) -> String {
        guard let x = e["x"], let y = e["y"], let w = e["width"], let h = e["height"] else { return "; Rechteck unvollständig" }
        let (xt, yt) = transform(x, y)
        return [
            cmd("MOVE_FAST", x: xt, y: yt),
            cmd("DRAW_LINE", x: xt + w, y: yt),
            cmd("DRAW_LINE", x: xt + w, y: yt + h),
            cmd("DRAW_LINE", x: xt, y: yt + h),
            cmd("DRAW_LINE", x: xt, y: yt)
        ].joined(separator: "\n")
    }

    /// Generates G-code for an SVG circle element.
    ///
    /// Approximates the circle as a series of linear segments using G0 (move) and G1 (line) commands.
    private func generateCircle(from e: SVGElement) -> String {
        guard let cx = e["cx"], let cy = e["cy"], let r = e["r"] else { return "; Kreis unvollständig" }
        let (cxt, cyt) = transform(cx, cy)
        return [
            cmd("MOVE_FAST", x: cxt + r, y: cyt),
            cmd("DRAW_LINE", x: cxt, y: cyt + r),
            cmd("DRAW_LINE", x: cxt - r, y: cyt),
            cmd("DRAW_LINE", x: cxt, y: cyt - r),
            cmd("DRAW_LINE", x: cxt + r, y: cyt)
        ].joined(separator: "\n")
    }

    /// Generates G-code for an SVG line element.
    ///
    /// Creates a straight line from the start point to the end point using G0 (move) and G1 (line) commands.
    private func generateLine(from e: SVGElement) -> String {
        guard let x1 = e["x1"], let y1 = e["y1"], let x2 = e["x2"], let y2 = e["y2"] else { return "; Linie unvollständig" }
        let (x1t, y1t) = transform(x1, y1)
        let (x2t, y2t) = transform(x2, y2)
        return [
            cmd("MOVE_FAST", x: x1t, y: y1t),
            cmd("DRAW_LINE", x: x2t, y: y2t)
        ].joined(separator: "\n")
    }

    /// Generates G-code for an SVG ellipse element.
    ///
    /// Approximates the ellipse as a series of linear segments using G0 (move) and G1 (line) commands.
    private func generateEllipse(from e: SVGElement) -> String {
        guard let cx = e["cx"], let cy = e["cy"], let rx = e["rx"], let ry = e["ry"] else { return "; Ellipse unvollständig" }
        let (cxt, cyt) = transform(cx, cy)
        return [
            cmd("MOVE_FAST", x: cxt + rx, y: cyt),
            cmd("DRAW_LINE", x: cxt, y: cyt + ry),
            cmd("DRAW_LINE", x: cxt - rx, y: cyt),
            cmd("DRAW_LINE", x: cxt, y: cyt - ry),
            cmd("DRAW_LINE", x: cxt + rx, y: cyt)
        ].joined(separator: "\n")
    }

    /// Generates G-code for an SVG polyline or polygon element.
    ///
    /// Processes the `points` attribute to create a sequence of G0 (move) and G1 (line) commands, optionally closing the path for polygons.
    private func generatePolyline(from e: SVGElement, close: Bool) -> String {
        guard let raw = e.rawAttributes["points"] else { return "; Polyline fehlt" }
        let coords = raw.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
        guard coords.count >= 4 else { return "; Polyline zu kurz" }

        var g = ""
        var firstX = 0.0, firstY = 0.0

        for i in stride(from: 0, to: coords.count, by: 2) {
            let (x, y) = transform(coords[i], coords[i + 1])
            if i == 0 {
                firstX = x; firstY = y
                g += cmd("MOVE_FAST", x: x, y: y) + "\n"
            } else {
                g += cmd("DRAW_LINE", x: x, y: y) + "\n"
            }
        }
        if close {
            g += cmd("DRAW_LINE", x: firstX, y: firstY) + " ; zurück zum Startpunkt\n"
        }
        return g
    }

    /// Generates G-code for an SVG path element by tokenizing its `d` attribute.
    ///
    /// This method is deprecated in favor of `parsePath(_:)` using `PathParser` for more robust parsing.
    private func generatePath(from e: SVGElement) -> String {
        guard let d = e.rawAttributes["d"] else { return "; Pfad fehlt" }
        var g = ""
        var x = 0.0, y = 0.0
        var startX = 0.0, startY = 0.0
        let tokens = d.replacingOccurrences(of: ",", with: " ").components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var index = 0

        /// Retrieves the next `count` tokens as `Double` values.
        func getDoubles(_ count: Int) -> [Double]? {
            guard index + count < tokens.count else { return nil }
            let values = tokens[(index + 1)...(index + count)].compactMap { Double($0) }
            return values.count == count ? values : nil
        }

        while index < tokens.count {
            let cmdToken = tokens[index]
            switch cmdToken {
            case "M", "m":
                if let vals = getDoubles(2) {
                    (x, y) = transform(vals[0], vals[1])
                    startX = x; startY = y
                    g += cmd("MOVE_FAST", x: x, y: y) + "\n"; index += 3
                } else { index += 1 }
            case "L", "l":
                if let vals = getDoubles(2) {
                    (x, y) = transform(vals[0], vals[1])
                    g += cmd("DRAW_LINE", x: x, y: y) + "\n"; index += 3
                } else { index += 1 }
            case "C", "c":
                if let vals = getDoubles(6) {
                    let p0 = (x, y)
                    let c1 = transform(vals[0], vals[1])
                    let c2 = transform(vals[2], vals[3])
                    let p3 = transform(vals[4], vals[5])
                    for (bx, by) in Math.cubicBezier(from: p0, c1: c1, c2: c2, to: p3) {
                        g += cmd("DRAW_LINE", x: bx, y: by) + "\n"
                    }
                    x = p3.0; y = p3.1; index += 7
                } else { index += 1 }
            case "Q", "q":
                if let vals = getDoubles(4) {
                    let p0 = (x, y)
                    let ctrl = transform(vals[0], vals[1])
                    let to = transform(vals[2], vals[3])
                    for (bx, by) in Math.quadraticBezier(from: p0, control: ctrl, to: to) {
                        g += cmd("DRAW_LINE", x: bx, y: by) + "\n"
                    }
                    x = to.0; y = to.1; index += 5
                } else { index += 1 }
            case "Z", "z":
                g += cmd("DRAW_LINE", x: startX, y: startY) + " ; Pfad geschlossen\n"
                x = startX; y = startY; index += 1
            case "A", "a":
                if let vals = getDoubles(7) {
                    let to = transform(vals[5], vals[6])
                    let arcPoints = PathParser.arcApprox(
                        from: (x, y), to: to,
                        rx: vals[0], ry: vals[1],
                        xAxisRotation: vals[2],
                        largeArc: vals[3] != 0,
                        sweep: vals[4] != 0
                    )
                    for pt in arcPoints.dropFirst() {
                        g += cmd("DRAW_LINE", x: pt.0, y: pt.1) + "\n"
                    }
                    x = to.0; y = to.1; index += 8
                } else { index += 1 }
            default:
                index += 1
            }
        }
        return g
    }
}
