//
//  BasePlotterGenerator.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

// BasePlotterGenerator.swift
import Foundation

/// A base class for generating plotter code from SVG elements, implementing the `PlotterCodeGenerator` protocol.
///
/// Provides transformation handling and utility methods for coordinate manipulation, intended to be subclassed for specific plotter formats (e.g., G-code, Eggbot).
class BasePlotterGenerator: PlotterCodeGenerator {
    
    /// A stack of transformation offsets (dx, dy) for handling nested transformations.
    var transformStack: [(dx: Double, dy: Double)] = [(0, 0)]
    
    /// Initializes an instance of `BasePlotterGenerator`.
    public init() {}
    
    /// Returns the current transformation offset.
    ///
    /// - Returns: A tuple containing the current `(dx, dy)` translation offsets, defaulting to `(0, 0)` if the stack is empty.
    public func currentTransform() -> (Double, Double) {
        return transformStack.last ?? (0, 0)
    }
    
    /// Applies the current transformation to a given point.
    ///
    /// Adds the current transformation offsets to the input coordinates.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate to transform.
    ///   - y: The y-coordinate to transform.
    /// - Returns: A tuple containing the transformed `(x, y)` coordinates.
    public func applyTransform(_ x: Double, _ y: Double) -> (Double, Double) {
        let (dx, dy) = currentTransform()
        return (x + dx, y + dy)
    }
    
    /// An alias for `applyTransform(_:_:)`.
    ///
    /// Applies the current transformation to a given point, provided for convenience and readability.
    ///
    /// - Parameters:
    ///   - x: The x-coordinate to transform.
    ///   - y: The y-coordinate to transform.
    /// - Returns: A tuple containing the transformed `(x, y)` coordinates.
    public func transform(_ x: Double, _ y: Double) -> (Double, Double) {
        return applyTransform(x, y)
    }
    
    /// Pushes a new transformation offset onto the stack.
    ///
    /// Combines the provided offsets with the current transformation to create a new cumulative offset.
    ///
    /// - Parameters:
    ///   - dx: The x-axis translation to add.
    ///   - dy: The y-axis translation to add.
    public func pushTransform(dx: Double, dy: Double) {
        let (cx, cy) = currentTransform()
        transformStack.append((cx + dx, cy + dy))
    }
    
    /// Removes the most recent transformation offset from the stack.
    ///
    /// If the stack is empty, no action is taken.
    public func popTransform() {
        _ = transformStack.popLast()
    }
    
    /// Splits a string of space- or comma-separated values into an array of `Double` values.
    ///
    /// Useful for parsing attributes like `points` in SVG polylines or polygons.
    ///
    /// - Parameter raw: The input string containing space- or comma-separated numeric values.
    /// - Returns: An array of `Double` values extracted from the string.
    public func splitDoubles(from raw: String) -> [Double] {
        raw.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Double($0) }
    }
    
    /// Generates plotter code for an SVG element.
    ///
    /// This is a placeholder implementation that must be overridden by subclasses to provide specific plotter code generation.
    ///
    /// - Parameter element: The SVG element to generate code for.
    /// - Returns: A string containing a comment indicating the method is not implemented.
    func generate(for element: SVGElement) -> String {
        return "; Nicht implementiert"
    }
}
