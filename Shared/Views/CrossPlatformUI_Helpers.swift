//
//  CrossPlatformUI_Helper.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 10.04.25.
//
// Eine Sammlung plattformabhängiger UI-Helfer für iOS & macOS
//
// Bereich               Modifier                        Wirkung (nur macOS, oder iOS wenn nötig)
// NavigationWrapper     .platformNavigationWrapper      Verwendet NavigationView nur auf iOS
// Textfeld              .platformTextFieldModifiers     Deaktiviert Autokorrektur etc. auf iOS
// Form-Layout           .platformFormStyle()            Aktiviert .automatic nur auf iOS
// Außenabstand der Form .platformFormPadding()          Fügt Padding und maxWidth auf macOS hinzu
// Abstand zw. Controls  .platformVerticalFormSpacing()  Fügt vertikalen Zwischenraum nur auf macOS ein
// Button-Stil           .platformPrimaryButtonStyle()   Verwendet borderedProminent auf iOS
// Button-Zentrierung    .platformCenteredButton()       Zentriert Button auf macOS
// decimalPad Nutzung    .crossPlatformDecimalKeyboard() Nutzt auf iOS .decimalPad, auf macOS bleibt es wirkungslos
// Header für macOS und iOS

// CrossPlatformUI_Helper.swift
import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct PlatformUIHelper {
    
    /// Gibt an, ob die aktuelle Plattform iOS ist
    static var isiOS: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    // Gibt an, ob die aktuelle Plattform macOS ist
    static var isMacOS: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
}

struct ScreenHelper {
    static var width: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.width
        #elseif os(macOS)
        return NSScreen.main?.visibleFrame.width ?? 0
        #endif
    }
    
    static var height: CGFloat {
        #if os(iOS)
        return UIScreen.main.bounds.height
        #elseif os(macOS)
        return NSScreen.main?.visibleFrame.height ?? 0
        #endif
    }
}

struct ColorHelper {
    static var backgroundColor: Color {
        #if os(iOS)
        return Color(.secondarySystemBackground)
        #elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
}


extension View {

    // Fügt iOS-Textfeldoptionen wie .autocorrection und .capitalization hinzu
    @ViewBuilder
    func platformTextFieldModifiers() -> some View {
        #if os(iOS)
        self
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
        #else
        self
        #endif
    }

    // Fügt iOS-Form-Styling hinzu (macOS ignoriert es)
    @ViewBuilder
    func platformFormStyle() -> some View {
        #if os(iOS)
        self.formStyle(.automatic)
        #else
        self
        #endif
    }

    // Nutzt NavigationView auf iOS, ignoriert auf macOS
    @ViewBuilder
    func platformNavigationWrapper<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(iOS)
        NavigationView {
            content()
        }
        #else
        content()
        #endif
    }

    // iOS prominent button style, fallback für macOS
    @ViewBuilder
    func platformPrimaryButtonStyle() -> some View {
        #if os(iOS)
        self.buttonStyle(.borderedProminent)
        #else
        self.buttonStyle(PlainButtonStyle())
        #endif
    }
    
    // Zusätzliches padding am Rand des Formulares auf MacOS
    @ViewBuilder
    func platformFormPadding() -> some View {
        #if os(macOS)
        self
            .padding()
            .frame(maxWidth: 600)
        #else
        self
        #endif
    }
    
    // Zentrierte Buttons auf macOS
    @ViewBuilder
    func platformCenteredButton() -> some View {
        #if os(macOS)
        HStack {
            Spacer()
            self
            Spacer()
        }
        #else
        self
        #endif
    }
    
    // Alle Controls wie TextField, Toggle, Picker, Button sollen auf macOS oben und unten etwas Abstand bekommen
    @ViewBuilder
    func platformVerticalFormSpacing(_ spacing: CGFloat = 8) -> some View {
        #if os(macOS)
        self
            .padding(.vertical, spacing)
        #else
        self
        #endif
    }
    
    // Nutzt auf iOS .decimalPad, auf macOS bleibt es wirkungslos
    @ViewBuilder
    func crossPlatformDecimalKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }
    
    // Header für macOS und iOS
    func platformSectionHeader(title: String) -> some View {
        #if os(macOS)
        return AnyView(Text(title).font(.headline))  // Return als AnyView für macOS
        #else
        return Text(title)  // Return als Text für iOS
        #endif
    }
    
    @ViewBuilder
    func platformBackButton(label: String = "Zurück", action: @escaping () -> Void) -> some View {
        #if os(macOS)
        VStack(alignment: .leading) {
            Button(label, action: action)
                .buttonStyle(.link)
                .padding(.bottom, 4)
            self
        }
        #else
        self // iOS macht nix
        #endif
    }
}
