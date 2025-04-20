//
//  EggbotGenerator.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

// EggbotGenerator.swift
import Foundation

final class EggbotGenerator: BasePlotterGenerator {
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

    private func parsePath(_ e: SVGElement) -> String {
        guard let d = e.rawAttributes["d"] else { return "; Pfad fehlt" }
        var g = ""
        var x = 0.0, y = 0.0
        var start = (0.0, 0.0)

        let parser = PathParser(d: d) { cmd, points, isRel in
            func move(to pt: (Double, Double)) {
                g += "SP,\(pt.0),\(pt.1)\n"; x = pt.0; y = pt.1
            }
            func draw(to pt: (Double, Double)) {
                g += "PD,\(pt.0),\(pt.1)\n"; x = pt.0; y = pt.1
            }
            switch cmd {
            case "M": let p = self.transform(points[0], points[1]); start = p; move(to: p)
            case "L": draw(to: self.transform(points[0], points[1]))
            case "C":
                let p0 = (x, y)
                let c1 = self.transform(points[0], points[1])
                let c2 = self.transform(points[2], points[3])
                let to = self.transform(points[4], points[5])
                for pt in self.cubicBezier(from: p0, c1: c1, c2: c2, to: to) { draw(to: pt) }
            case "Q":
                let p0 = (x, y)
                let ctrl = self.transform(points[0], points[1])
                let to = self.transform(points[2], points[3])
                for pt in self.quadraticBezier(from: p0, control: ctrl, to: to) { draw(to: pt) }
            case "A":
                let to = self.transform(points[5], points[6])
                let arcPoints = PathParser.arcApprox(
                    from: (x, y),
                    to: to,
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
        return g + "PU"
    }

    private func move(to x: Double, _ y: Double) -> String {
        "SP,\(x),\(y)"
    }

    private func draw(to x: Double, _ y: Double) -> String {
        "PD,\(x),\(y)"
    }

    private func generateRect(from e: SVGElement) -> String {
        guard let x = e.attributes["x"], let y = e.attributes["y"],
              let w = e.attributes["width"], let h = e.attributes["height"] else {
            return "; Rechteck unvollständig"
        }
        let (xt, yt) = transform(x, y)
        return [
            move(to: xt, yt),
            draw(to: xt + w, yt),
            draw(to: xt + w, yt + h),
            draw(to: xt, yt + h),
            draw(to: xt, yt),
            "PU"
        ].joined(separator: "\n")
    }

    private func generateCircle(from e: SVGElement) -> String {
        guard let cx = e.attributes["cx"], let cy = e.attributes["cy"], let r = e.attributes["r"] else {
            return "; Kreis unvollständig"
        }
        let segments = 24
        var g = ""
        for i in 0...segments {
            let angle = 2 * Double.pi * Double(i) / Double(segments)
            let x = cx + cos(angle) * r
            let y = cy + sin(angle) * r
            let (xt, yt) = transform(x, y)
            g += i == 0 ? move(to: xt, yt) : "\n" + draw(to: xt, yt)
        }
        return g + "\nPU"
    }

    private func generateEllipse(from e: SVGElement) -> String {
        guard let cx = e.attributes["cx"], let cy = e.attributes["cy"],
              let rx = e.attributes["rx"], let ry = e.attributes["ry"] else {
            return "; Ellipse unvollständig"
        }
        let segments = 24
        var g = ""
        for i in 0...segments {
            let angle = 2 * Double.pi * Double(i) / Double(segments)
            let x = cx + cos(angle) * rx
            let y = cy + sin(angle) * ry
            let (xt, yt) = transform(x, y)
            g += i == 0 ? move(to: xt, yt) : "\n" + draw(to: xt, yt)
        }
        return g + "\nPU"
    }

    private func generateLine(from e: SVGElement) -> String {
        guard let x1 = e.attributes["x1"], let y1 = e.attributes["y1"],
              let x2 = e.attributes["x2"], let y2 = e.attributes["y2"] else {
            return "; Linie unvollständig"
        }
        let (x1t, y1t) = transform(x1, y1)
        let (x2t, y2t) = transform(x2, y2)
        return """
        \(move(to: x1t, y1t))
        \(draw(to: x2t, y2t))
        PU
        """
    }

    private func generatePolyline(from e: SVGElement, close: Bool) -> String {
        guard let raw = e.rawAttributes["points"] else { return "; Polyline fehlt" }
        let coords = splitDoubles(from: raw)
        guard coords.count >= 4 else { return "; Polyline zu kurz" }

        var g = ""
        var firstX = 0.0, firstY = 0.0

        for i in stride(from: 0, to: coords.count - 1, by: 2) {
            let (x, y) = transform(coords[i], coords[i + 1])
            if i == 0 {
                firstX = x; firstY = y
                g += move(to: x, y)
            } else {
                g += "\n" + draw(to: x, y)
            }
        }

        if close {
            g += "\n" + draw(to: firstX, firstY)
        }
        return g + "\nPU"
    }

    private func generatePath(from e: SVGElement) -> String {
        guard let d = e.rawAttributes["d"] else { return "; Pfad fehlt" }
        var g = ""
        var x = 0.0, y = 0.0
        var startX = 0.0, startY = 0.0
        let tokens = d.replacingOccurrences(of: ",", with: " ").components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        var index = 0

        func getDoubles(_ count: Int) -> [Double]? {
            guard index + count < tokens.count else { return nil }
            let values = tokens[(index + 1)...(index + count)].compactMap { Double($0) }
            return values.count == count ? values : nil
        }

        while index < tokens.count {
            let cmd = tokens[index]
            switch cmd {
            case "M", "m":
                if let vals = getDoubles(2) {
                    (x, y) = transform(vals[0], vals[1])
                    startX = x; startY = y
                    g += move(to: x, y) + "\n"; index += 3
                } else { index += 1 }
            case "L", "l":
                if let vals = getDoubles(2) {
                    (x, y) = transform(vals[0], vals[1])
                    g += draw(to: x, y) + "\n"; index += 3
                } else { index += 1 }
            case "C", "c":
                if let vals = getDoubles(6) {
                    let p0 = (x, y)
                    let c1 = transform(vals[0], vals[1])
                    let c2 = transform(vals[2], vals[3])
                    let p3 = transform(vals[4], vals[5])
                    let points = cubicBezier(from: p0, c1: c1, c2: c2, to: p3)
                    for pt in points { g += draw(to: pt.0, pt.1) + "\n" }
                    x = p3.0; y = p3.1; index += 7
                } else { index += 1 }
            case "Q", "q":
                if let vals = getDoubles(4) {
                    let p0 = (x, y)
                    let ctrl = transform(vals[0], vals[1])
                    let to = transform(vals[2], vals[3])
                    let points = quadraticBezier(from: p0, control: ctrl, to: to)
                    for pt in points { g += draw(to: pt.0, pt.1) + "\n" }
                    x = to.0; y = to.1; index += 5
                } else { index += 1 }
            case "Z", "z":
                g += draw(to: startX, startY) + "\n"
                x = startX; y = startY; index += 1
            case "A", "a":
                if let vals = getDoubles(7) {
                    let rx = vals[0], ry = vals[1]
                    let xAxisRotation = vals[2]
                    let largeArc = vals[3] != 0
                    let sweep = vals[4] != 0
                    let x1 = vals[5], y1 = vals[6]
                    let to = transform(x1, y1)
                    // Für Eggbot als einfache Linie
                    g += draw(to: to.0, to.1) + "\n"
                    x = to.0; y = to.1
                    index += 8
                } else { index += 1 }
            default:
                index += 1
            }
        }
        return g + "PU"
    }
}
