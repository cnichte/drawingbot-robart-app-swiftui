//
//  PathParser.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

// PathParser.swift
import Foundation

final class PathParser {
    typealias CommandHandler = (_ cmd: String, _ values: [Double], _ isRelative: Bool) -> Void

    private let d: String
    private let handler: CommandHandler

    init(d: String, handler: @escaping CommandHandler) {
        self.d = d
        self.handler = handler
    }

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

    static func argumentCount(for command: String) -> Int {
        switch command.lowercased() {
        case "m", "l": return 2
        case "h", "v": return 1
        case "c": return 6
        case "s": return 4
        case "q": return 4
        case "t": return 2
        case "a": return 7
        case "z": return 0
        default: return 0
        }
    }

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
