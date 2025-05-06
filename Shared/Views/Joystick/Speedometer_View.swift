//
//  Speedometer_View.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 06.04.25.
//

// Speedometer_View.swift
import SwiftUI

struct Speedometer_View: View {
    
    var stickValues:StickValues
    
    var body: some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {
            if(stickValues.stickTypeRaw == RemoteControlStickType.standard.rawValue){
                // Move-Angle text
                Text(stickValues.angleText)
                    .font(.title)
                    .foregroundColor(.white)
                    .bold()
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                // Move-Speed text
                Text(stickValues.speedText)
                    .font(.title)
                    .foregroundColor(.white)
                    .bold()
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                Text(stickValues.positionText)
                    .font(.title)
                    .foregroundColor(.white)
                    .bold()
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }else { // stickValues.stickType == .rotate
                // Rotation text
                Text(stickValues.rotationText)
                    .font(.title)
                    .foregroundColor(.white)
                    .bold()
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
            }


        } // HStack
    } // body
} // Speedometer_View

#Preview {
    Speedometer_View(stickValues: .default)
}
