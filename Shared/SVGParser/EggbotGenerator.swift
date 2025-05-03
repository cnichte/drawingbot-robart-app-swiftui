//
//  EggbotGenerator.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

/*
 "commandItems":[
   {
     "id": "885b5cff-d9c2-4420-aeba-e9dcb061020f",
     "name": "MOVE_TO",
     "command": "SP,{X},{Y}",
     "description": "Positionieren mit Stift oben"
   },
   {
     "id": "637f3fa9-c47f-4b09-9809-f3476fa7cc62",
     "name": "DRAW_TO",
     "command": "PD,{X},{Y}",
     "description": "Zeichne mit Stift unten"
   },
   {
     "id": "dfa87d12-e803-4bb5-b281-74676dd66ab7",
     "name": "PEN_UP",
     "command": "PU",
     "description": "Stift anheben"
   }
 ]
 */

// EggbotGenerator.swift
import Foundation

/// A class that generates Eggbot-compatible code for SVG elements, extending `BasePlotterGenerator`.
final class EggbotGenerator: BasePlotterGenerator {
    private let resolver: MachineCommandResolver

    init(machineData: MachineData) {
        self.resolver = MachineCommandResolver(commandItems: machineData.commandItems)
    }

    /// Generates Eggbot code for a given SVG element based on its type.
    ///
    /// Supports SVG elements such as lines, rectangles, circles, ellipses, polylines, polygons, and paths. Uses `SP` (move, pen up) and `PD` (draw, pen down) commands, ending with `PU` (pen up).
    override func generate(for e: SVGElement) -> String {
        switch e.name {
        case "line": return generateLine(from: e)
        case "rect": return generateRect(from: e)
        case "circle": return generateCircle(from: e)
        case "ellipse": return generateEllipse(from: e)
        case "polyline": return generatePolyline(from: e, close: false)
        case "polygon": return generatePolyline(from: e, close: true)
        case "path": return parsePath(e)
        default: return "; \(e.name) nicht unterstützt"
        }
    }

    /// Ersetzt Platzhalter im Template anhand `name` und Koordinaten.
    private func cmd(_ name: String, x: Double, y: Double) -> String {
        resolver.resolve(name: name, variables: ["X": x, "Y": y]) ?? "; fehlend: \(name)"
    }

    private func penUp() -> String {
        resolver.resolve(name: "PEN_UP", variables: [:]) ?? "; fehlend: PEN_UP"
    }

    /// Parses an SVG path element and generates Eggbot code for its commands.
    ///
    /// Uses `PathParser` to process the path’s `d` attribute and generates code for supported commands (e.g., MoveTo, LineTo, Cubic Bezier, Quadratic Bezier, Arc, ClosePath).
    private func parsePath(_ e: SVGElement) -> String {
        guard let d = e.rawAttributes["d"] else { return "; Pfad fehlt" }
        var g = ""
        var x = 0.0, y = 0.0
        var start = (0.0, 0.0)

        let parser = PathParser(d: d) { cmdName, points, isRel in
            func move(to pt: (Double, Double)) {
                g += self.cmd("MOVE_TO", x: pt.0, y: pt.1) + "\n"
                x = pt.0; y = pt.1
            }

            func draw(to pt: (Double, Double)) {
                g += self.cmd("DRAW_TO", x: pt.0, y: pt.1) + "\n"
                x = pt.0; y = pt.1
            }

            switch cmdName {
            case "M": let p = self.transform(points[0], points[1]); start = p; move(to: p)
            case "L": draw(to: self.transform(points[0], points[1]))
            case "C":
                let p0 = (x, y)
                let c1 = self.transform(points[0], points[1])
                let c2 = self.transform(points[2], points[3])
                let to = self.transform(points[4], points[5])
                for pt in Math.cubicBezier(from: p0, c1: c1, c2: c2, to: to) { draw(to: pt) }
            case "Q":
                let p0 = (x, y)
                let ctrl = self.transform(points[0], points[1])
                let to = self.transform(points[2], points[3])
                for pt in Math.quadraticBezier(from: p0, control: ctrl, to: to) { draw(to: pt) }
            case "A":
                let to = self.transform(points[5], points[6])
                let arcPoints = PathParser.arcApprox(
                    from: (x, y), to: to,
                    rx: points[0], ry: points[1],
                    xAxisRotation: points[2],
                    largeArc: points[3] != 0,
                    sweep: points[4] != 0
                )
                for pt in arcPoints.dropFirst() { draw(to: pt) }
            case "Z": draw(to: start)
            default: break
            }
        }
        parser.parse()
        return g + penUp()
    }
    
    /// Generates Eggbot code for an SVG rectangle element.
    ///
    /// Creates a closed path around the rectangle’s perimeter using `SP` and `PD` commands, ending with `PU`.
    ///
    /// - Parameter e: The SVG rectangle element.
    /// - Returns: A string containing the Eggbot code for the rectangle, or a comment if attributes are missing.
    private func generateRect(from e: SVGElement) -> String {
        guard let x = e["x"], let y = e["y"],
              let w = e["width"], let h = e["height"] else {
            return "; Rechteck unvollständig"
        }
        let (xt, yt) = transform(x, y)
        return [
            cmd("MOVE_TO", x: xt, y: yt),
            cmd("DRAW_TO", x: xt + w, y: yt),
            cmd("DRAW_TO", x: xt + w, y: yt + h),
            cmd("DRAW_TO", x: xt, y: yt + h),
            cmd("DRAW_TO", x: xt, y: yt),
            penUp()
        ].joined(separator: "\n")
    }
    
    /// Generates Eggbot code for an SVG circle element.
    ///
    /// Approximates the circle with 24 linear segments using `SP` and `PD` commands, ending with `PU`.
    ///
    /// - Parameter e: The SVG circle element.
    /// - Returns: A string containing the Eggbot code for the circle, or a comment if attributes are missing.
    private func generateCircle(from e: SVGElement) -> String {
        guard let cx = e["cx"], let cy = e["cy"], let r = e["r"] else {
            return "; Kreis unvollständig"
        }
        let segments = 24
        var g = ""
        for i in 0...segments {
            let angle = 2 * Double.pi * Double(i) / Double(segments)
            let (x, y) = transform(cx + cos(angle) * r, cy + sin(angle) * r)
            g += i == 0 ? cmd("MOVE_TO", x: x, y: y) : "\n" + cmd("DRAW_TO", x: x, y: y)
        }
        return g + "\n" + penUp()
    }
    
    /// Generates Eggbot code for an SVG ellipse element.
    ///
    /// Approximates the ellipse with 24 linear segments using `SP` and `PD` commands, ending with `PU`.
    ///
    /// - Parameter e: The SVG ellipse element.
    /// - Returns: A string containing the Eggbot code for the ellipse, or a comment if attributes are missing.
    private func generateEllipse(from e: SVGElement) -> String {
        guard let cx = e["cx"], let cy = e["cy"], let rx = e["rx"], let ry = e["ry"] else {
            return "; Ellipse unvollständig"
        }
        let segments = 24
        var g = ""
        for i in 0...segments {
            let angle = 2 * Double.pi * Double(i) / Double(segments)
            let (x, y) = transform(cx + cos(angle) * rx, cy + sin(angle) * ry)
            g += i == 0 ? cmd("MOVE_TO", x: x, y: y) : "\n" + cmd("DRAW_TO", x: x, y: y)
        }
        return g + "\n" + penUp()
    }
    
    /// Generates Eggbot code for an SVG line element.
    ///
    /// Creates a straight line from the start point to the end point using `SP` and `PD` commands, ending with `PU`.
    ///
    /// - Parameter e: The SVG line element.
    /// - Returns: A string containing the Eggbot code for the line, or a comment if attributes are missing.
    private func generateLine(from e: SVGElement) -> String {
        guard let x1 = e["x1"], let y1 = e["y1"],
              let x2 = e["x2"], let y2 = e["y2"] else {
            return "; Linie unvollständig"
        }
        let (x1t, y1t) = transform(x1, y1)
        let (x2t, y2t) = transform(x2, y2)
        return """
        \(cmd("MOVE_TO", x: x1t, y: y1t))
        \(cmd("DRAW_TO", x: x2t, y: y2t))
        \(penUp())
        """
    }
    
    /// Generates Eggbot code for an SVG polyline or polygon element.
    ///
    /// Processes the `points` attribute to create a sequence of `SP` and `PD` commands, optionally closing the path for polygons, ending with `PU`.
    ///
    /// - Parameters:
    ///   - e: The SVG polyline or polygon element.
    ///   - close: A flag indicating whether to close the path (true for polygons, false for polylines).
    /// - Returns: A string containing the Eggbot code for the polyline/polygon, or a comment if points are missing or insufficient.
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
                g += cmd("MOVE_TO", x: x, y: y)
            } else {
                g += "\n" + cmd("DRAW_TO", x: x, y: y)
            }
        }

        if close {
            g += "\n" + cmd("DRAW_TO", x: firstX, y: firstY)
        }

        return g + "\n" + penUp()
    }
}
