//
//  ToastView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 10.04.25.
//

import SwiftUI

// MARK: - Toast ViewModifier

enum ToastPosition {
    case top, bottom
}

struct ToastModifier: ViewModifier {
    let message: String
    @Binding var isPresented: Bool
    let position: ToastPosition
    let duration: Double
    let type: ToastType

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                if position == .top, isPresented {
                    HStack {
                        Spacer()
                        ToastView(
                            message: message,
                            backgroundColor: type.backgroundColor,
                            icon: type.icon
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                        Spacer()
                    }
                    .padding(.top, PlatformUIHelper.isMacOS ? 40 : 60)
                }
                Spacer()
                if position == .bottom, isPresented {
                    HStack {
                        Spacer()
                        ToastView(
                            message: message,
                            backgroundColor: type.backgroundColor,
                            icon: type.icon
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1)
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
            }
        }
    }
}


extension View {
    func toast(
        message: String,
        isPresented: Binding<Bool>,
        position: ToastPosition = .top,
        duration: Double = 5,
        type: ToastType = .info
    ) -> some View {
        self.modifier(
            ToastModifier(
                message: message,
                isPresented: isPresented,
                position: position,
                duration: duration,
                type: type
            )
        )
    }
}


// MARK: - Toast Types

enum ToastType {
    case info, success, error

    var backgroundColor: Color {
        switch self {
        case .info: return Color.accentColor.opacity(0.95)
        case .success: return Color.green.opacity(0.9)
        case .error: return Color.red.opacity(0.9)
        }
    }

    var icon: String {
        switch self {
        case .info: return "info.circle"
        case .success: return "checkmark.circle"
        case .error: return "xmark.octagon"
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    var backgroundColor: Color = Color.accentColor.opacity(0.95)
    var icon: String = "info.circle"

    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(message)
        }
        .font(.footnote)
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}
#Preview {
    ToastView(message: "Message!")
}
