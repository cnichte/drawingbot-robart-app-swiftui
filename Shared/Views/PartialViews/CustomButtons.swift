//
//  CustomButton.swift
//  Robart
//
//  Created by Carsten Nichte on 03.05.25.
//

import SwiftUI

enum CustomButtonStyleType {
    case primary
    case secondary
    case destructive
}

// MARK: - CustomButton

struct CustomButton: View {
    let title: String
    let icon: String? // Optional: Systemname des SF Symbols
    let style: CustomButtonStyleType
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
    let style: CustomButtonStyleType
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

// MARK: - CustomToolbarToggle

struct CustomToolbarToggle: View {
    let title: String
    let icon: String? // Optional: Systemname des SF Symbols
    let style: CustomButtonStyleType
    let hasBorder: Bool // Steuert, ob ein Rahmen angezeigt wird
    let iconSize: Image.Scale // Steuert die Symbolgröße (.small, .medium, .large)
    @Binding var isOn: Bool // Zustand des Toggles
    
    @State private var isHovered = false // Zustand für Hover
    
    var body: some View {
        Toggle(isOn: $isOn) {
            LabelView(title: title, icon: icon, iconSize: iconSize)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .foregroundColor(foregroundColor)
                .background(hoverBackground)
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
    
    // Separate View für das Label, um Typ-Inferenz zu vereinfachen
    private struct LabelView: View {
        let title: String
        let icon: String?
        let iconSize: Image.Scale
        
        var body: some View {
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
        switch style {
        case .primary:
            Color.blue.opacity(isOn ? 0.3 : (isHovered ? 0.2 : 0.1)) // Aktiv: dunkler
        case .secondary:
            Color.gray.opacity(isOn ? 0.2 : (isHovered ? 0.1 : 0.0)) // Aktiv: sichtbar
        case .destructive:
            Color.red.opacity(isOn ? 0.3 : (isHovered ? 0.2 : 0.1)) // Aktiv: dunkler
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

// MARK: - CustomToolbarPicker mit Content-Closure
// CustomToolbarPicker als segmentierter Picker

struct CustomToolbarPicker<Option: Hashable, Content: View>: View {
    let title: String
    let icon: String? // Optional: Systemname des SF Symbols
    let style: CustomButtonStyleType
    let hasBorder: Bool // Steuert, ob ein Rahmen angezeigt wird
    let iconSize: Image.Scale // Steuert die Symbolgröße (.small, .medium, .large)
    @Binding var selection: Option // Ausgewählte Option
    let content: () -> Content // Closure für die Optionen (z. B. ForEach)
    
    @State private var isHovered = false // Zustand für Hover
    
    var body: some View {
        Picker("", selection: $selection) {
            content()
        }
        .pickerStyle(.segmented) // Segmentierter Picker
        .labelsHidden() // Standard-Label ausblenden
        .buttonStyle(.plain) // Plattformunabhängiges Styling
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .foregroundColor(foregroundColor)
        .background(hoverBackground)
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
        .contentShape(Rectangle()) // Für bessere Touch-/Maus-Erkennung
        .onHover { hovering in
            isHovered = hovering // Aktualisiert den Hover-Zustand
        }
        .frame(width: 100) // Angepasste Breite für nur Symbole
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
        switch style {
        case .primary:
            Color.blue.opacity(isHovered ? 0.2 : 0.1) // Heller bei Hover
        case .secondary:
            Color.gray.opacity(isHovered ? 0.1 : 0.0) // Subtiler Hover-Effekt
        case .destructive:
            Color.red.opacity(isHovered ? 0.2 : 0.1) // Heller bei Hover
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
