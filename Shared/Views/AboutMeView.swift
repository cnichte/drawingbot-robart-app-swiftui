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

            Text("Robart App")
                .font(.title2)
                .bold()

            Text("Hi! Ich bin ein Asset Manager.\n\nIch organisiere, dokumentiere und drucke Plotter-Art Projekte im SVG-Format.\n\nIch kann über Bluetooth oder USB mit einem DrawingBot (zB. Axidraw oder Robart dem Ploboter) reden,\n\nund visualisiere die Roboteraktivitäten.\n\n© 2025 Carsten Nichte")
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
