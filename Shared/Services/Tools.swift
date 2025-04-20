//
//  Tools.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 13.04.25.
//

// Math, Transformations
// Tools.swift
import Foundation
import SwiftUI

class Tools {
    // Helper function to format number as a double with decimal format
    static func formatNumberAsDouble(value: Double) -> String {
        return String(format: "%.2f", value)
    }

    // Helper function to create a TextField for String values
    static func textField(label: String, value: Binding<String>) -> some View {
        return TextField(label, text: value)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
    }

    // Helper function to create a TextField for CGFloat values
    static func CGFloatTextField(label: String, value: Binding<CGFloat>) -> some View {
        return TextField(label, value: Binding(
            get: { Double(value.wrappedValue) },
            set: { value.wrappedValue = CGFloat($0) }
        ), format: .number)
            .crossPlatformDecimalKeyboard()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
    }

    // Helper function to create a TextField for Double values
    static func doubleTextField(label: String, value: Binding<Double>) -> some View {
        return TextField(label, value: value, format: .number)
            .crossPlatformDecimalKeyboard()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
    }

    // Helper function to create a TextField for Int values
    static func intTextField(label: String, value: Binding<Int>) -> some View {
        return TextField(label, value: value, format: .number)
            .crossPlatformDecimalKeyboard()
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
    }

    // Helper function to create a Stepper for Int values
    static func intStepper(label: String, value: Binding<Int>) -> some View {
        return Stepper(label, value: value)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal)
    }

    // Helper function to create a Slider for Double values
    static func slider(value: Binding<Double>, range: ClosedRange<Double>, label: String) -> some View {
        return Slider(value: value, in: range)
            .onChange(of: value.wrappedValue) { }
            .padding()
    }
}
