//
//  PathParser.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

// PathParser.swift
import Foundation

import Foundation

/// A class for parsing SVG path data (`d` attribute) and invoking a handler for each command.
final class PathParser {
    /// A closure type for handling parsed path commands and their values.
    typealias CommandHandler = (_ cmd: String, _ values: [Double], _ isRelative: Bool) -> Void
    
    /// The SVG path data string to parse.
    private let d: String
    
    /// The handler closure to invoke for each parsed command.
    private let handler: CommandHandler
    
    /// Initializes the parser with a path data string and a handler closure.
    ///
    /// - Parameters:
    ///   - d: The SVG path data string (e.g., "M10,20L30,40").
    ///   - handler: A closure to handle each parsed command, its values, and whether it is relative.
    init(d: String, handler: @escaping CommandHandler) {
        self.d = d
        self.handler = handler
    }
    
    /// Parses the path data string and invokes the handler for each command.
    ///
    /// Processes the `d` string by tokenizing it and interpreting commands and their arguments.
    func parse() {
        let tokens = tokenize(d)
        var index = 0
        var currentCmd: String?
        
        while index < tokens.count {
            let token = tokens[index]
            
            if let num = Double(token), let cmd = currentCmd {
                let argCount = PathParser.argumentCount(for: cmd)
                if argCount == 0 {
                    handler(cmd, [], cmd.lowercased() == cmd)
                    index += 1
                    continue
                }
                if index + argCount <= tokens.count {
                    let values = tokens[index..<index + argCount].compactMap(Double.init)
                    if values.count == argCount {
                        handler(cmd, values, cmd.lowercased() == cmd)
                        index += argCount
                        continue
                    }
                }
                break
            } else {
                currentCmd = token
                index += 1
                guard let cmd = currentCmd else { continue }
                let argCount = PathParser.argumentCount(for: cmd)
                if argCount == 0 {
                    handler(cmd, [], cmd.lowercased() == cmd)
                    continue
                }
                while index + argCount <= tokens.count {
                    let sub = tokens[index..<index + argCount]
                    if sub.allSatisfy({ Double($0) != nil }) {
                        let values = sub.compactMap(Double.init)
                        handler(cmd, values, cmd.lowercased() == cmd)
                        index += argCount
                    } else {
                        break
                    }
                }
            }
        }
    }
    
    /// Tokenizes the path data string into an array of commands and values.
    ///
    /// Splits the input string into letters (commands) and numbers (arguments), ignoring whitespace and commas.
    ///
    /// - Parameter input: The SVG path data string to tokenize.
    /// - Returns: An array of strings representing commands and their arguments.
    private func tokenize(_ input: String) -> [String] {
        var result: [String] = []
        var current = ""
        
        for char in input {
            if char.isLetter {
                if !current.isEmpty {
                    result.append(current)
                    current = ""
                }
                result.append(String(char))
            } else if char.isWhitespace || char == "," {
                if !current.isEmpty {
                    result.append(current)
                    current = ""
                }
            } else {
                current.append(char)
            }
        }
        if !current.isEmpty {
            result.append(current)
        }
        
        return result
    }
    
    /// Returns the expected number of arguments for a given SVG path command.
    ///
    /// - Parameter command: The SVG path command (e.g., "M", "L", "C").
    /// - Returns: The number of arguments required by the command.
    static func argumentCount(for command: String) -> Int {
        switch command.lowercased() {
        case "m", "l": return 2 // MoveTo, LineTo
        case "h", "v": return 1 // Horizontal Line, Vertical Line
        case "c": return 6 // Cubic Bezier
        case "s": return 4 // Smooth Cubic Bezier
        case "q": return 4 // Quadratic Bezier
        case "t": return 2 // Smooth Quadratic Bezier
        case "a": return 7 // Arc
        case "z": return 0 // ClosePath
        default: return 0
        }
    }
    
    /// Approximates an SVG arc as a series of points.
    ///
    /// Converts an SVG arc command into a sequence of points using elliptical arc parameterization.
    ///
    /// - Parameters:
    ///   - from: The starting point of the arc as a tuple of `(x, y)` coordinates.
    ///   - to: The ending point of the arc as a tuple of `(x, y)` coordinates.
    ///   - rx: The x-radius of the ellipse.
    ///   - ry: The y-radius of the ellipse.
    ///   - xAxisRotation: The rotation angle of the ellipse's x-axis in degrees.
    ///   - largeArc: A flag indicating whether to use the large arc (`true`) or small arc (`false`).
    ///   - sweep: A flag indicating whether to sweep the arc in the positive angle direction (`true`) or negative (`false`).
    ///   - segments: The number of segments to approximate the arc. Defaults to 20.
    /// - Returns: An array of `(Double, Double)` tuples representing points along the arc.
    static func arcApprox(from: (Double, Double), to: (Double, Double), rx: Double, ry: Double, xAxisRotation: Double, largeArc: Bool, sweep: Bool, segments: Int = 20) -> [(Double, Double)] {
        let φ = xAxisRotation * Double.pi / 180
        let cosφ = cos(φ), sinφ = sin(φ)
        
        let dx = (from.0 - to.0) / 2
        let dy = (from.1 - to.1) / 2
        let x1p = cosφ * dx + sinφ * dy
        let y1p = -sinφ * dx + cosφ * dy
        
        var rxAdj = abs(rx)
        var ryAdj = abs(ry)
        let λ = (x1p * x1p) / (rxAdj * rxAdj) + (y1p * y1p) / (ryAdj * ryAdj)
        if λ > 1 {
            rxAdj *= sqrt(λ)
            ryAdj *= sqrt(λ)
        }
        
        let sign: Double = (largeArc != sweep) ? 1 : -1
        let numerator = (rxAdj * rxAdj * ryAdj * ryAdj) - (rxAdj * rxAdj * y1p * y1p) - (ryAdj * ryAdj * x1p * x1p)
        let denom = (rxAdj * rxAdj * y1p * y1p) + (ryAdj * ryAdj * x1p * x1p)
        let factor = sign * sqrt(max(0, numerator / denom))
        let cxp = factor * (rxAdj * y1p) / ryAdj
        let cyp = factor * -(ryAdj * x1p) / rxAdj
        
        let cx = cosφ * cxp - sinφ * cyp + (from.0 + to.0) / 2
        let cy = sinφ * cxp + cosφ * cyp + (from.1 + to.1) / 2
        
        /// Calculates the angle between two vectors.
        ///
        /// - Parameters:
        ///   - u: The first vector as a tuple of `(x, y)` coordinates.
        ///   - v: The second vector as a tuple of `(x, y)` coordinates.
        /// - Returns: The angle in radians between the vectors.
        func angle(u: (Double, Double), v: (Double, Double)) -> Double {
            let dot = u.0 * v.0 + u.1 * v.1
            let det = u.0 * v.1 - u.1 * v.0
            return atan2(det, dot)
        }
        
        let startVec = ((x1p - cxp) / rxAdj, (y1p - cyp) / ryAdj)
        let endVec = ((-x1p - cxp) / rxAdj, (-y1p - cyp) / ryAdj)
        var θ1 = angle(u: (1, 0), v: startVec)
        var Δθ = angle(u: startVec, v: endVec)
        if !sweep && Δθ > 0 { Δθ -= 2 * .pi }
        if sweep && Δθ < 0 { Δθ += 2 * .pi }
        
        var points: [(Double, Double)] = []
        for i in 0...segments {
            let t = θ1 + Δθ * Double(i) / Double(segments)
            let x = cosφ * rxAdj * cos(t) - sinφ * ryAdj * sin(t) + cx
            let y = sinφ * rxAdj * cos(t) + cosφ * ryAdj * sin(t) + cy
            points.append((x, y))
        }
        return points
    }
}
