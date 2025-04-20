//
//  BasePlotterGenerator.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

// BasePlotterGenerator.swift
import Foundation

class BasePlotterGenerator: PlotterCodeGenerator {
    
    var transformStack: [(dx: Double, dy: Double)] = [(0, 0)]

    public init() {}

    public func currentTransform() -> (Double, Double) {
        return transformStack.last ?? (0, 0)
    }

    public func applyTransform(_ x: Double, _ y: Double) -> (Double, Double) {
        let (dx, dy) = currentTransform()
        return (x + dx, y + dy)
    }
    
    // Optionaler Alias
    public func transform(_ x: Double, _ y: Double) -> (Double, Double) {
        return applyTransform(x, y)
    }

    public func pushTransform(dx: Double, dy: Double) {
        let (cx, cy) = currentTransform()
        transformStack.append((cx + dx, cy + dy))
    }

    public func popTransform() {
        _ = transformStack.popLast()
    }

    // z. B. auch hilfreich als Hilfsmethode
    public func splitDoubles(from raw: String) -> [Double] {
        raw.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
    }

    func cubicBezier(from p0: (Double, Double), c1: (Double, Double), c2: (Double, Double), to p3: (Double, Double), steps: Int = 20) -> [(Double, Double)] {
        var points: [(Double, Double)] = []
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let x = pow(1 - t, 3) * p0.0 + 3 * pow(1 - t, 2) * t * c1.0 + 3 * (1 - t) * pow(t, 2) * c2.0 + pow(t, 3) * p3.0
            let y = pow(1 - t, 3) * p0.1 + 3 * pow(1 - t, 2) * t * c1.1 + 3 * (1 - t) * pow(t, 2) * c2.1 + pow(t, 3) * p3.1
            points.append((x, y))
        }
        return points
    }

    func quadraticBezier(from p0: (Double, Double), control: (Double, Double), to p2: (Double, Double), steps: Int = 20) -> [(Double, Double)] {
        var points: [(Double, Double)] = []
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let x = pow(1 - t, 2) * p0.0 + 2 * (1 - t) * t * control.0 + pow(t, 2) * p2.0
            let y = pow(1 - t, 2) * p0.1 + 2 * (1 - t) * t * control.1 + pow(t, 2) * p2.1
            points.append((x, y))
        }
        return points
    }

    func approximateArc(from start: (Double, Double), to end: (Double, Double), rx: Double, ry: Double, xAxisRotation: Double, largeArc: Bool, sweep: Bool, steps: Int = 20) -> [(Double, Double)] {
        // Sehr vereinfachte Approximation: Interpolation auf Gerade (falls volle Ellipsen-Geometrie nicht nötig ist)
        var points: [(Double, Double)] = []
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let x = (1 - t) * start.0 + t * end.0
            let y = (1 - t) * start.1 + t * end.1
            points.append((x, y))
        }
        return points
    }
    
    // Dummy-Implementierung, wird in Subklassen überschrieben
    func generate(for element: SVGElement) -> String {
        return "; Nicht implementiert"
    }
}
