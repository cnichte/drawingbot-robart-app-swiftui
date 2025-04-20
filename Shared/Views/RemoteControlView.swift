//
//  RemoteControlView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 08.04.25.
//

import SwiftUI

struct RemoteControlView: View {
    @ObservedObject var bluetoothManager: BluetoothManager

    // Speedometer
    @State private var angleText = "0"
    @State private var speedText = "0"
    @State private var rotationText = "0"
    
    @State private var leftStickPosition: CGPoint = .zero
    @State private var rightStickPosition: CGPoint = .zero
    
    @State var leftStickDefaultMode = true
    @State var rightStickDefaultMode = false
    
    private let joystickRadius: CGFloat = 60
    private let knobRadius: CGFloat = 30
    
   // Geräte merken (z. B. Favoriten) - Für gezielten Auto-Reconnect
   // 🗂 Sortierung nach Namen oder manuell - Für bessere Übersicht
   // 📲 Verbindungssymbol + Name oben in UI- Wie bei AirPods oder Gerätenamen
    
    var body: some View {
        
        VStack(spacing: 15) {
            
            Speedometer_View(angleText: angleText, speedText: speedText, rotationText: rotationText)
            
            .padding()
            
            Spacer() // Optional: sorgt für den Abstand am unteren Ende
            
            // HStack - Joysticks
            HStack(
                alignment: .top,
                spacing: 50
            ) {
                // Left Joystick
                Joystick_View(position: $leftStickPosition, default_mode: $leftStickDefaultMode, angleText:$angleText, speedText:$speedText, rotateText: $rotationText)
                
                // Right Joystick
                Joystick_View(position: $rightStickPosition, default_mode: $rightStickDefaultMode ,angleText:$angleText, speedText:$speedText, rotateText: $rotationText)
            } // HStack - Joysticks
        }
        .padding()
        .navigationTitle("Fernsteuerung")
    }
}


struct RemoteControlView_Previews: PreviewProvider {
    static var previews: some View {
        RemoteControlView(bluetoothManager: MockBluetoothManager())
    }
}
