//
//  CustomButton.swift
//  Robart
//
//  Created by Carsten Nichte on 03.05.25.
//

import SwiftUI

enum ButtonStyleType {
    case primary
    case secondary
    case destructive
}

// MARK: - CustomButton

struct CustomButton: View {
    let title: String
    let icon: String? // Optional: Systemname des SF Symbols
    let style: ButtonStyleType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .imageScale(.medium)
                }
                if !title.isEmpty {
                    Text(title)
                        .fontWeight(.medium)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundColor(foregroundColor)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .buttonStyle(PlainButtonStyle()) // Plattformunabhängiges Styling
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .blue
        case .destructive:
            return .red
        }
    }
    
    private var background: some View {
        switch style {
        case .primary:
            return Color.blue
        case .secondary:
            return Color.clear
        case .destructive:
            return Color.red.opacity(0.1)
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary:
            return .clear
        case .secondary:
            return .blue
        case .destructive:
            return .red
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary:
            return 0
        case .secondary, .destructive:
            return 1
        }
    }
}

// MARK: - CustomToolbarButton

struct CustomToolbarButton: View {
    let title: String
    let icon: String? // Optional: Systemname des SF Symbols
    let style: ButtonStyleType
    let role: ButtonRole? // Für Toolbar-Rollen wie .destructiveAction
    let hasBorder: Bool // Steuert, ob ein Rahmen angezeigt wird
    let iconSize: Image.Scale // Steuert die Symbolgröße (.small, .medium, .large)
    let action: () -> Void
    
    @State private var isHovered = false // Zustand für Hover
    
    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .imageScale(iconSize)
                }
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .foregroundColor(foregroundColor)
            .background(hoverBackground) // Dynamischer Hintergrund basierend auf Hover
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                Group {
                    if hasBorder {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(borderColor, lineWidth: 1)
                    }
                }
            )
            .scaleEffect(isHovered ? 1.05 : 1.0) // Leichte Skalierung bei Hover
        }
        .buttonStyle(.plain) // Plattformunabhängiges Styling
        .contentShape(Rectangle()) // Für bessere Touch-/Maus-Erkennung
        .onHover { hovering in
            isHovered = hovering // Aktualisiert den Hover-Zustand
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .blue
        case .secondary:
            return .gray
        case .destructive:
            return .red
        }
    }
    
    private var hoverBackground: some View {
        Group {
            switch style {
            case .primary:
                return Color.blue.opacity(isHovered ? 0.2 : 0.1) // Heller bei Hover
            case .secondary:
                return Color.gray.opacity(isHovered ? 0.1 : 0.0) // Subtiler Hover-Effekt
            case .destructive:
                return Color.red.opacity(isHovered ? 0.2 : 0.1) // Heller bei Hover
            }
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary:
            return .blue
        case .secondary:
            return .gray
        case .destructive:
            return .red
        }
    }
}
