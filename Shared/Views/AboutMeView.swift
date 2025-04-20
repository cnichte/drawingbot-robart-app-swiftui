//
//  AboutMeView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 08.04.25.
//

import SwiftUI

struct AboutMeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            Text("RobArt der Plobotter")
                .font(.title2)
                .bold()

            Text("Diese App dient zur Bluetooth Kommunikation mit dem DrawingBot RobArt, und zur Visualisierung der Roboteraktivitäten.\n\n© 2025 Carsten Nichte")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("Weiterführende Links")
                .font(.title2)
                .bold()
            
            // Anklickbare URL
            Link("Homepage carsten-nichte.de", destination: URL(string: "https://carsten-nichte.de/")!)
                .font(.body)
                .foregroundColor(.blue)
                .underline()
            Link("Dokumentation auf der Homepage", destination: URL(string: "https://carsten-nichte.de/docs/drawingbot/")!)
                .font(.body)
                .foregroundColor(.blue)
                .underline()
            
            Spacer()
        }
        .padding()
        .navigationTitle("Über mich")
    }
}

#Preview {
    AboutMeView()
}
