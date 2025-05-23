//
//  Double.swift
//  Robart
//
//  Created by Carsten Nichte on 23.05.25.
//
import SwiftUI

extension Double {
    var clean: String {
        self == floor(self) ? String(format: "%.0f", self) : String(format: "%.1f", self)
    }
}
