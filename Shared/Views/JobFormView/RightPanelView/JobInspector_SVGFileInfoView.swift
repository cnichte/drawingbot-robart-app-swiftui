//
//  JobInspector_SVGFileInfoView.swift
//  Robart
//
//  Created by Carsten Nichte on 01.05.25.
//

// JobInspector_SVGFileInfoView.swift
import SwiftUI

struct JobInspector_SVGFileInfoView: View {
    @Binding var currentJob: JobData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allgemeine Datei-Informationen")
                .font(.headline)

            Text("Dateiname: (folgt)")
            Text("Dateigröße: (folgt)")
            Text("Erstellt am: (folgt)")
        }
    }
}
