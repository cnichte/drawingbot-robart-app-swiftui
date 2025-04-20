//
//  Joystick_View.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 06.04.25.
//

import SwiftUI

// This is a Joystick with two Modes.
struct Joystick_View: View {
    // set the position of th knob
    @Binding var position: CGPoint
    @Binding var default_mode:Bool
    
    // give info back to parent View
    @Binding var angleText: String
    @Binding var speedText: String
    @Binding var rotateText: String
    
    // TODO: Knob should end inside the joystick circle.
    private let joystickRadius: CGFloat = 75
    private let knobRadius: CGFloat = 30
    
    private let initialAngle: CGFloat = 0
    
    // calculate the move_angle
    func calculate_angleText(angle: CGFloat) -> Void {
        var degrees = Int(-angle * 180 / .pi)
        // Convert the degrees to a positive value
        if degrees < 0 {
            degrees += 360
        }
        angleText = "\(degrees)°"
    } // angleText
    
    // calculate the move_speed
    func calculate_speedText(distance: CGFloat) -> Void  {
        // Translate speed from 0 to 100% independet from joystickRadius
        // with some percentage calculation: p = P * 100 / K
        let p = distance * 100 / joystickRadius
        speedText = "\(String(format: "%.1f", p)) %"
    } // speedText
    
    // calculate the move_angle
    func calculate_rotationText(angle: CGFloat) -> Void {
        var degrees = Int(-angle * 180 / .pi)
        // Convert the degrees to a positive value
        if degrees < 0 {
            degrees += 360
        }
        rotateText = "\(degrees)°"
    } // angleText
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: joystickRadius * 2, height: joystickRadius * 2)
            
            Circle()
                .fill(Color.white)
                // smaller knobRadius in special-mode
                .frame(width: (default_mode ? knobRadius * 2 : knobRadius), height: (default_mode ? knobRadius * 2 : knobRadius) )
                .offset(x: position.x, y: position.y)
                .onAppear {
                    if(default_mode){
                        // stick ist centered
                    }else{
                        // Initiale Position bei 45 Grad
                        let angle = initialAngle * .pi / 180 // Umrechnung in Bogenmaß
                        calculate_rotationText(angle: angle)
                        
                        let x = cos(angle) * joystickRadius
                        let y = sin(angle) * joystickRadius
                        position = CGPoint(x: x, y: y)
                    }
                   }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let dx = value.translation.width
                            let dy = value.translation.height
                            let distance = sqrt(dx*dx + dy*dy)
                            let angle = atan2(dy, dx)
                            
                            if(default_mode){
                                
                                if distance <= joystickRadius {
                                    position = CGPoint(x: dx, y: dy)
                                    
                                    calculate_speedText(distance: distance);
                                    calculate_angleText(angle: angle);
                                } else {
                                    // Clamp to joystick edge
                                    
                                    let clampedX = cos(angle) * joystickRadius
                                    let clampedY = sin(angle) * joystickRadius
                                    position = CGPoint(x: clampedX, y: clampedY)
                                    
                                    // clamped distance = radius outer circle
                                    calculate_speedText(distance: joystickRadius);
                                    calculate_angleText(angle: angle);
                                }
                                
                            }else{
                                // Spezialmodus: Der Knopf bewegt sich nur auf dem Radius
                                
                                // Berechne den Winkel zur Mitte des Joysticks
                                calculate_rotationText(angle: angle)
                                
                                // Berechne die neue Position des Knopfes auf dem Rand des Joysticks
                                let clampedX = cos(angle) * joystickRadius
                                let clampedY = sin(angle) * joystickRadius
                                // Setze die neue Position des Knopfes entlang des Randes
                                position = CGPoint(x: clampedX, y: clampedY)
                            }
                        }
                        .onEnded { _ in
                            if(default_mode){
                                position = .zero // Reset to center
                            }else{
                                // Knopf bleibt am Rand des Joysticks, keine Rücksetzung
                                // TODO winkel = 0 oder 90 ?? über einen Resetknopf ??
                            }
                            
                            calculate_angleText(angle: 0.0);
                            calculate_speedText(distance: 0.0);
                        }
                )
        }
    }
}

#Preview {
    @Previewable @State var angleText = "0"
    @Previewable @State var speedText = "0"
    @Previewable @State var rotateText = "0"
    @Previewable @State var default_mode = true
    @Previewable @State var stickPosition: CGPoint = .zero
    
    Joystick_View(position: $stickPosition, default_mode: $default_mode, angleText:$angleText, speedText:$speedText, rotateText: $rotateText)
        .position(x: ScreenHelper.width * 0.5, y: ScreenHelper.height * 0.5)
        .background(Color.black.opacity(0.7))
}
