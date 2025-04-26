//
//  Speedometer_View.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 06.04.25.
//

import SwiftUI

struct Speedometer_View: View {
    
    var angleText: String
    var speedText: String
    var rotationText: String
    
    var body: some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {
            // Move-Angle text
            Text(angleText)
                .font(.title)
                .foregroundColor(.white)
                .bold()
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
            // Move-Speed text
            Text(speedText)
                .font(.title)
                .foregroundColor(.white)
                .bold()
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
            // Rotation text
            Text(rotationText)
                .font(.title)
                .foregroundColor(.white)
                .bold()
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(10)
        } // HStack
    } // body
} // Speedometer_View

#Preview {
    Speedometer_View(angleText: "angle",speedText: "speed",rotationText: "rotation")
}
