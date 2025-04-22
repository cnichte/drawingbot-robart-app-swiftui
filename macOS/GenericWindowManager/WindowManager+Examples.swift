//
//   WindowManager+Examples.swift
//  Robart
//
//  Created by Carsten Nichte on 17.04.25.
//
#if os(macOS)
/*
import SwiftUI
import AppKit

// Beispiel 1: ProjektEditorView mit EnvironmentObjects
Button("Projekte") {
    WindowManager.shared.openWithEnvironmentObjects(
        ProjectEditorView(),
        id: .projectEditor,
        title: "Projekte verwalten",
        width: 900,
        height: 600,
        environmentObjects: [
            EnvironmentObjectModifier(object: projectStore),
            EnvironmentObjectModifier(object: jobStore)
        ]
    )
}
.buttonStyle(.borderedProminent)

// Beispiel 2: Sheet-Style Fenster mit Inhalt
Button("Details anzeigen") {
    WindowManager.shared.openSheet(
        JobDetailView(job: selectedJob),
        title: "Job-Details",
        width: 500,
        height: 300
    )
}

// Beispiel 3: Popover-Style Info
Button("Hilfe") {
    WindowManager.shared.openPopover(
        Text("Hier steht eine hilfreiche Erkl\u00E4rung.")
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading),
        title: "Hilfe",
        width: 300,
        height: 150
    )
}
 
 ------------------------
 
 @State private var showSheet = false
 @State private var showPopover = false
 @State private var showAlert = false

 var body: some View {
     VStack {
         Button("Sheet öffnen") {
             showSheet = true
         }
         .sheetWithEnvironmentObjects(isPresented: $showSheet, environmentObjects: [
             EnvironmentObjectModifier(object: projectStore)
         ]) {
             ProjectEditorView()
         }

         Button("Popover öffnen") {
             showPopover = true
         }
         .popoverWithEnvironmentObjects(isPresented: $showPopover) {
             Text("Dies ist ein Popover!")
                 .padding()
         }

         Button("Alert zeigen") {
             showAlert = true
         }
         .simpleAlert(isPresented: $showAlert, title: "Fehler", message: "Etwas ist schiefgelaufen.")
     }
 }
 
*/
#endif
