//
//  Math.swift
//  Robart
//
//  Created by Carsten Nichte on 25.04.25.
//

import Foundation

/// Utility class providing methods for generating points along Bezier curves and approximating arcs.
class Math {
    
    /// Generates points along a cubic Bezier curve defined by a start point, two control points, and an end point.
    ///
    /// - Parameters:
    ///   - p0: The starting point of the curve as a tuple of `(x, y)` coordinates.
    ///   - c1: The first control point as a tuple of `(x, y)` coordinates.
    ///   - c2: The second control point as a tuple of `(x, y)` coordinates.
    ///   - p3: The ending point of the curve as a tuple of `(x, y)` coordinates.
    ///   - steps: The number of points to generate along the curve. Defaults to 20.
    /// - Returns: An array of `(Double, Double)` tuples representing points along the cubic Bezier curve.
    public static func cubicBezier(from p0: (Double, Double), c1: (Double, Double), c2: (Double, Double), to p3: (Double, Double), steps: Int = 20) -> [(Double, Double)] {
        var points: [(Double, Double)] = []
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let x = pow(1 - t, 3) * p0.0 + 3 * pow(1 - t, 2) * t * c1.0 + 3 * (1 - t) * pow(t, 2) * c2.0 + pow(t, 3) * p3.0
            let y = pow(1 - t, 3) * p0.1 + 3 * pow(1 - t, 2) * t * c1.1 + 3 * (1 - t) * pow(t, 2) * c2.1 + pow(t, 3) * p3.1
            points.append((x, y))
        }
        return points
    }
    
    /// Generates points along a quadratic Bezier curve defined by a start point, a control point, and an end point.
    ///
    /// - Parameters:
    ///   - p0: The starting point of the curve as a tuple of `(x, y)` coordinates.
    ///   - control: The control point as a tuple of `(x, y)` coordinates.
    ///   - p2: The ending point of the curve as a tuple of `(x, y)` coordinates.
    ///   - steps: The number of points to generate along the curve. Defaults to 20.
    /// - Returns: An array of `(Double, Double)` tuples representing points along the quadratic Bezier curve.
    public static func quadraticBezier(from p0: (Double, Double), control: (Double, Double), to p2: (Double, Double), steps: Int = 20) -> [(Double, Double)] {
        var points: [(Double, Double)] = []
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let x = pow(1 - t, 2) * p0.0 + 2 * (1 - t) * t * control.0 + pow(t, 2) * p2.0
            let y = pow(1 - t, 2) * p0.1 + 2 * (1 - t) * t * control.1 + pow(t, 2) * p2.1
            points.append((x, y))
        }
        return points
    }
    
    /// Approximates an elliptical arc by generating points between a start and end point.
    ///
    /// This is a simplified implementation that interpolates points along a straight line instead of computing a full elliptical arc.
    ///
    /// - Parameters:
    ///   - start: The starting point of the arc as a tuple of `(x, y)` coordinates.
    ///   - end: The ending point of the arc as a tuple of `(x, y)` coordinates.
    ///   - rx: The x-radius of the ellipse.
    ///   - ry: The y-radius of the ellipse.
    ///   - xAxisRotation: The rotation angle of the ellipse's x-axis in radians.
    ///   - largeArc: A flag indicating whether to use the large arc (true) or small arc (false).
    ///   - sweep: A flag indicating whether to sweep the arc in the positive angle direction (true) or negative (false).
    ///   - steps: The number of points to generate along the arc. Defaults to 20.
    /// - Returns: An array of `(Double, Double)` tuples representing points along the approximated arc.
    public static func approximateArc(from start: (Double, Double), to end: (Double, Double), rx: Double, ry: Double, xAxisRotation: Double, largeArc: Bool, sweep: Bool, steps: Int = 20) -> [(Double, Double)] {
        // Simplified approximation: Linear interpolation between start and end points
        var points: [(Double, Double)] = []
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let x = (1 - t) * start.0 + t * end.0
            let y = (1 - t) * start.1 + t * end.1
            points.append((x, y))
        }
        return points
    }
}
