//
//  Joystick_View.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 06.04.25.
//

// Joystick_View.swift
import SwiftUI
import Foundation
import CoreGraphics
import Combine

// MARK: - StickType, StickMode

public enum RemoteControlStickType: String, Codable {
    case standard = ".standard"
    case rotate = ".rotate"
}

// New StickMode for StickType .standard
public enum RemoteControlStickMode: String, Codable {
    case free = ".free"
    case fixedX  = ".fixedX"
    case fixedY  = ".fixedY"
    case fixedXY = ".fixedXY"
}

// MARK: - StickValues

// Bundle all the values for a stick...
final class StickValues: ObservableObject, Equatable, Cloneable {
    // ObservableObject
    @Published var stickTypeRaw: String
    @Published var stickModeRaw: String
    
    @Published var position: CGPoint // mode .standard
    @Published var angle: CGFloat
    @Published var speed: CGFloat
    
    @Published var rotation: CGFloat // mode .rotation
    
    @Published var positionText: String
    @Published var angleText: String
    @Published var speedText: String
    @Published var rotationText: String
    
    static var `default`: StickValues {
        StickValues()
    }
    
    init(
        stickType: RemoteControlStickType = .standard,
        stickMode: RemoteControlStickMode = .free,
        position: CGPoint = .zero,
        angle: CGFloat = 0,
        speed: CGFloat = 0,
        rotation: CGFloat = 0,
        positionText: String = "(0,0)",
        angleText: String = "0",
        speedText: String = "0",
        rotationText: String = "0"
    ) {
        self.stickTypeRaw = stickType.rawValue
        self.stickModeRaw = stickMode.rawValue
        self.position = position
        self.angle = angle
        self.speed = speed
        self.rotation = rotation
        self.positionText = positionText
        self.angleText = angleText
        self.speedText = speedText
        self.rotationText = rotationText
    }
    
    // Equatable
    static func == (lhs: StickValues, rhs: StickValues) -> Bool {
        lhs.stickTypeRaw == rhs.stickTypeRaw &&
        lhs.stickModeRaw == rhs.stickModeRaw &&
        lhs.position == rhs.position &&
        lhs.angle == rhs.angle &&
        lhs.speed == rhs.speed &&
        lhs.rotation == rhs.rotation &&
        lhs.positionText == rhs.positionText &&
        lhs.angleText == rhs.angleText &&
        lhs.speedText == rhs.speedText &&
        lhs.rotationText == rhs.rotationText
    }
    
    // Cloneable
    func clone() -> StickValues {
        let copy = StickValues(
            stickType: RemoteControlStickType(rawValue: self.stickTypeRaw) ?? .standard,
            stickMode: RemoteControlStickMode(rawValue: self.stickModeRaw) ?? .free,
            position: self.position,
            angle: self.angle,
            speed: self.speed,
            rotation: self.rotation,
            positionText: self.positionText,
            angleText: self.angleText,
            speedText: self.speedText,
            rotationText: self.rotationText
        )
        return copy
    }
    
}

// MARK: - CombinedStickValues

final class CombinedStickValues: ObservableObject, Equatable, Cloneable {
    
    @Published var left: StickValues
    @Published var right: StickValues
    
    init(left: StickValues, right: StickValues) {
        self.left = left
        self.right = right
    }
    
    func clone() -> CombinedStickValues {
        CombinedStickValues(
            left: left.clone(),
            right: right.clone()
        )
    }
    
    static func == (lhs: CombinedStickValues, rhs: CombinedStickValues) -> Bool {
        lhs.left == rhs.left && lhs.right == rhs.right
    }
}

// MARK: - Joystick_View

// This is a Joystick with two Modes: standard and rotation
// Joystick_View.swift
struct Joystick_View: View {
    
    @ObservedObject var stickValues: StickValues
    @State private var absolutPosition: CGPoint = .zero
    
    private let joystickRadius: CGFloat = 75
    private let knobRadius: CGFloat = 30
    private let initialAngle: CGFloat = 0
    
    private func format(_ value: CGFloat) -> String {
        return String(format: "%.1f", value)
    }
    
    // calculate the move_angle
    func calculate_angle(angle: CGFloat) -> Void {
        
        var degrees = CGFloat(-angle * 180 / .pi)
        
        // Convert the degrees to a positive value
        if degrees < 0 {
            degrees += 360
        }
        stickValues.angle = degrees
        stickValues.angleText = "\(self.format(degrees))°"
    } // calculate the move_angle
    
    // calculate the move_speed
    func calculate_speed(distance: CGFloat) -> Void  {
        // Translate speed from 0 to 100% independet from joystickRadius
        // with some percentage calculation: p = P * 100 / K
        let p = distance * 100 / joystickRadius
        
        stickValues.speed = p
        stickValues.speedText = "\(self.format(p))%"
    } // calculate the move_speed
    
    
    // calculate the postion in %
    func calculate_position(x: CGFloat, y: CGFloat) -> Void  {
        absolutPosition = CGPoint(x: x, y: y)
        // Q1: +x -y Q2: -x -y Q3: -x +y Q4: x+ y+
        // Translate position from 0 to 100% independet from joystickRadius
        // with some percentage calculation: p = P * 100 / K
        let x1 =  x * 100 / joystickRadius
        let y1 =  -y * 100 / joystickRadius // Invertiere Y-Koordinate für klassisches Koordinatensystem (oben = +y)
        stickValues.position = CGPoint(x: x1, y: y1)
        stickValues.positionText = "(\(self.format(x1)), \(self.format(y1)))"
    } // calculate_position
    
    // calculate the rotation_angle
    func calculate_rotation(angle: CGFloat) -> Void {
        var degrees = CGFloat(-angle * 180 / .pi)
        // Convert the degrees to a positive value
        if degrees < 0 {
            degrees += 360
        }
        stickValues.rotation = degrees
        stickValues.rotationText = "\(self.format(degrees))°"
    } // calculate_rotation
    
    var body: some View {
        
        ZStack {
            Circle() // Background
                .fill(Color.gray.opacity(0.3))
                .frame(width: joystickRadius * 2, height: joystickRadius * 2)
            
            Circle() // Stick
                .fill(Color.white)
                .frame(
                    width: ((stickValues.stickTypeRaw == RemoteControlStickType.standard.rawValue)  ? knobRadius * 2 : knobRadius),
                    height: ((stickValues.stickTypeRaw == RemoteControlStickType.standard.rawValue) ? knobRadius * 2 : knobRadius))
                .offset(x: self.absolutPosition.x, y: self.absolutPosition.y)
                .onAppear {
                    if !(stickValues.stickTypeRaw == RemoteControlStickType.standard.rawValue) {
                        let angle = initialAngle * .pi / 180
                        calculate_rotation(angle: angle)
                        let x = cos(angle) * joystickRadius
                        let y = sin(angle) * joystickRadius
                        
                        self.calculate_position(x: x,y: y)
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let dx = value.translation.width
                            let dy = value.translation.height
                            let distance = sqrt(dx * dx + dy * dy)
                            let angle = atan2(dy, dx)
                            
                            if (stickValues.stickTypeRaw == RemoteControlStickType.standard.rawValue) {
                                // Standard Joystick
                                if distance <= joystickRadius {
                                    calculate_position(x: dx,y: dy)
                                    calculate_speed(distance: distance)
                                    calculate_angle(angle: angle)
                                } else {
                                    let clampedX = cos(angle) * joystickRadius
                                    let clampedY = sin(angle) * joystickRadius
                                    
                                    calculate_position(x: clampedX,y: clampedY)
                                    calculate_speed(distance: joystickRadius)
                                    calculate_angle(angle: angle)
                                }
                            } else {
                                // Special Rotation Joystick
                                calculate_rotation(angle: angle)
                                let clampedX = cos(angle) * joystickRadius
                                let clampedY = sin(angle) * joystickRadius
                                self.calculate_position(x: clampedX,y: clampedY)
                            }
                        }
                        .onEnded { _ in
                            if (stickValues.stickTypeRaw == RemoteControlStickType.standard.rawValue) {
                                self.calculate_position(x: 0,y: 0)
                            }
                            calculate_angle(angle: 0.0)
                            calculate_speed(distance: 0.0)
                        }
                )
        }
    }
}

/*
 #Preview {
 @Previewable @State var angleText = "0"
 @Previewable @State var speedText = "0"
 @Previewable @State var rotateText = "0"
 @Previewable @State var default_mode = true
 @Previewable @State var stickPosition: CGPoint = .zero
 
 Joystick_View() .position(x: ScreenHelper.width * 0.5, y: ScreenHelper.height * 0.5) .background(Color.black.opacity(0.7))
 }
 */
