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

// MARK: - Plattform-Erkennung
struct PlatformUIHelper {
    static var isiOS: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }

    static var isMacOS: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Bildschirmgrößen
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

// MARK: - Farb-Hilfen
struct ColorHelper {
    static var backgroundColor: Color {
        #if os(iOS)
        return Color(.secondarySystemBackground)
        #elseif os(macOS)
        return Color(NSColor.controlBackgroundColor)
        #endif
    }
}

// MARK: - View-Erweiterungen
extension View {

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

    @ViewBuilder
    func platformFormStyle() -> some View {
        #if os(iOS)
        self.formStyle(.automatic)
        #else
        self
        #endif
    }

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

    @ViewBuilder
    func platformPrimaryButtonStyle() -> some View {
        #if os(iOS)
        self.buttonStyle(.borderedProminent)
        #else
        self.buttonStyle(PlainButtonStyle())
        #endif
    }

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

    @ViewBuilder
    func platformVerticalFormSpacing(_ spacing: CGFloat = 8) -> some View {
        #if os(macOS)
        self.padding(.vertical, spacing)
        #else
        self
        #endif
    }

    @ViewBuilder
    func crossPlatformDecimalKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }

    func platformSectionHeader(title: String) -> some View {
        #if os(macOS)
        return AnyView(Text(title).font(.headline))
        #else
        return Text(title)
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
        self
        #endif
    }

    // MARK: - Buttons Styles

    @ViewBuilder
    func buttonStyleLinkIfAvailable() -> some View {
        #if os(macOS)
        self.buttonStyle(.link)
        #else
        self.buttonStyle(.plain)
        #endif
    }

    @ViewBuilder
    func platformAddButtonStyle() -> some View {
        self
            .foregroundColor(.accentColor)
            .buttonStyleLinkIfAvailable()
    }

    @ViewBuilder
    func platformDeleteButtonStyle() -> some View {
        self
            .foregroundColor(.red)
            .buttonStyle(.borderless)
    }

    @ViewBuilder
    func platformPrimaryActionButton() -> some View {
        self
            .platformPrimaryButtonStyle()
            .platformCenteredButton()
            .padding(.top)
    }

    @ViewBuilder
    func platformSecondaryButtonStyle() -> some View {
        #if os(iOS)
        self.buttonStyle(.bordered)
        #else
        self.buttonStyle(.plain)
        #endif
    }

    @ViewBuilder
    func platformTextActionStyle() -> some View {
        self
            .font(.callout)
            .foregroundColor(.accentColor)
            .buttonStyleLinkIfAvailable()
    }

    // MARK: - Labels

    func platformIconLabel(_ title: String, systemImage: String, font: Font = .body) -> some View {
        Label {
            Text(title).font(font)
        } icon: {
            Image(systemName: systemImage)
        }
    }

    func platformTextLabel(_ title: String, font: Font = .body) -> some View {
        Text(title).font(font)
    }

    func platformIconOnly(_ systemImage: String, font: Font = .body) -> some View {
        Image(systemName: systemImage).font(font)
    }

    // MARK: - Toolbar Buttons

    @ViewBuilder
    func platformToolbarButton(
        label: String? = nil,
        systemImage: String? = nil,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        #if os(macOS)
        Button(role: role, action: action) {
            HStack(spacing: 6) {
                if let image = systemImage {
                    Image(systemName: image)
                }
                if let text = label {
                    Text(text)
                }
            }
        }.buttonStyle(.link)
        #else
        Button(role: role, action: action) {
            Label {
                Text(label ?? "")
            } icon: {
                if let image = systemImage {
                    Image(systemName: image)
                }
            }
        }.buttonStyle(.bordered)
        #endif
    }

    @ViewBuilder
    func platformToolbarItem(
        placement: ToolbarItemPlacement = .automatic,
        label: String? = nil,
        systemImage: String? = nil,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) -> some View {
        toolbar {
            ToolbarItem(placement: placement) {
                self.platformToolbarButton(
                    label: label,
                    systemImage: systemImage,
                    role: role,
                    action: action
                )
            }
        }
    }
}

// MARK: - Sidebar + Inspector Toolbar Support

struct PlatformSidebarAndInspectorToolbar: ViewModifier {
    let toggleSidebar: () -> Void
    let toggleInspector: () -> Void

    func body(content: Content) -> some View {
        content
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button(action: toggleInspector) {
                        Image(systemName: "sidebar.trailing")
                    }
                }
#else
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button(action: toggleSidebar) {
                        Image(systemName: "sidebar.leading")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: toggleInspector) {
                        Image(systemName: "sidebar.trailing")
                    }
                }
#endif
            }
    }
}

extension View {
    /// Fügt auf macOS und iOS eine Toolbar mit Sidebar- und Inspector-Toggle hinzu
    func platformSidebarAndInspectorToolbar(
        toggleSidebar: @escaping () -> Void,
        toggleInspector: @escaping () -> Void
    ) -> some View {
        self.modifier(PlatformSidebarAndInspectorToolbar(
            toggleSidebar: toggleSidebar,
            toggleInspector: toggleInspector
        ))
    }
}
