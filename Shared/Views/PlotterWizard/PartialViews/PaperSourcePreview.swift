//
//  PaperSourcePreview.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 15.04.25.
//

import SwiftUI

struct PaperSourcePreview: View {
    var job: PlotJobData

    var body: some View {
        ScrollView {
            Text("Hier könnte der SVG- oder GCode-Quelltext stehen.")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
