//
//  SVGTreeView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 13.04.25.
//

import SwiftUI

struct SVGTreeView: View {
    @Binding var currentJob: JobData

    var body: some View {
        List {
            ForEach(currentJob.svgFilePath.split(separator: "/"), id: \.self) { component in
                Text(String(component))
            }
        }
        .frame(minWidth: 200)
        .navigationTitle("SVG Tree View")
    }
}
