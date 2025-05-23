//
//  View+HoverEffect.swift
//  Robart
//
//  Created by Carsten Nichte on 28.04.25.
//

// View+HoverEffect.swift
import SwiftUI

extension View {
    func hoverLiftEffect() -> some View {
        self
            .scaleEffect(1.0)
            .shadow(color: .clear, radius: 0) // Default Zustand
            .overlay(
                GeometryReader { geo in
                    Color.clear
                        .onHover { isHovering in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if isHovering {
                                    geo.frame(in: .local)
                                    self.scaleEffect(1.02)
                                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                } else {
                                    self.scaleEffect(1.0)
                                        .shadow(color: .clear, radius: 0)
                                }
                            }
                        }
                }
            )
    }
}
