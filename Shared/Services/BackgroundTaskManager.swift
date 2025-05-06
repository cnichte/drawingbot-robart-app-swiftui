//
//  BackgroundTaskManager.swift
//  Robart
//
//  Created by Carsten Nichte on 06.05.25.
//

// BackgroundTaskManager.swift
import Foundation
import SwiftUI

protocol Cloneable {
    func clone() -> Self
}

class BackgroundTaskManager<T: Equatable & Cloneable>: ObservableObject {
    
    var timer: Timer?
    
    private var currentData: T? // Aktuelle Daten
    private var lastSentData: T? // Zuletzt gesendete Daten
    
    private let dataQueue = DispatchQueue(label: "de.nichte.robart.dataQueue")
    @Published var isRunning: Bool = false
    
    typealias OnSend = (T, @escaping (Bool) -> Void) -> Void // Callback
    
    func startBackgroundTask(onSend: @escaping OnSend) {
        guard !isRunning else { return }
        // 0.5 reicht für Bluetooth
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkAndPerformTask(onSend: onSend)
        }
        
        RunLoop.current.add(timer!, forMode: .common)
        DispatchQueue.main.async {
            self.isRunning = true
        }
    }
    
    func updateData(_ data: T) {
        dataQueue.async {
            self.currentData = data.clone()
        }
    }
    
    private func checkAndPerformTask(onSend: @escaping OnSend) {
        dataQueue.sync {
            guard let data = currentData, data != lastSentData else {
                appLog(.error, "Daten unverändert: \(String(describing: currentData)) um \(Date())")
                return
            }
            
            appLog(.info, "Daten geändert, sende: \(data) um \(Date())")
            lastSentData = data
            
            // You have to do the sending yourself in the callback....
            onSend(data) { success in
                appLog(.info, "Sendevorgang \(success ? "erfolgreich" : "fehlgeschlagen")")
            }
        }
    }
    
    func stopBackgroundTask() {
        timer?.invalidate()
        timer = nil
        DispatchQueue.main.async {
            self.isRunning = false
        }
    }
}

/*
 // SwiftUI-Ansicht
 struct ContentView: View {
     @StateObject private var taskManager = BackgroundTaskManager()
     @State private var stickValues: StickValues = .default
     
     var body: some View {
         VStack(spacing: 20) {
             // Statusanzeige
             Text(taskManager.isRunning ? "Task läuft" : "Task läuft nicht")
                 .font(.headline)
                 .foregroundColor(taskManager.isRunning ? .green : .red)
             
             // Button zum Ein-/Ausschalten
             Button(action: {
                 if taskManager.isRunning {
                     taskManager.stopBackgroundTask()
                 } else {
                     taskManager.startBackgroundTask(data: stickValues) { data, completion in
                         // Beispiel für eine Send-Mechanik (z. B. Netzwerkaufruf)
                         print("Sende Daten: stickType=\(data.stickTypeRaw), angle=\(data.angleText)")
                         // Simuliere einen asynchronen Sendevorgang
                         DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                             completion(true) // Erfolg melden
                         }
                     }
                 }
             }) {
                 Text(taskManager.isRunning ? "Task stoppen" : "Task starten")
                     .font(.title2)
                     .padding()
                     .frame(maxWidth: .infinity)
                     .background(taskManager.isRunning ? Color.red : Color.blue)
                     .foregroundColor(.white)
                     .cornerRadius(10)
             }
             .padding(.horizontal)
             
             // Eingabefelder für Test-Daten
             TextField("Angle", text: $stickValues.angleText)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .padding(.horizontal)
             
             TextField("Speed", text: $stickValues.speedText)
                 .textFieldStyle(RoundedBorderTextFieldStyle())
                 .padding(.horizontal)
         }
         .padding()
         .onChange(of: stickValues) { newData in
             if taskManager.isRunning {
                 taskManager.startBackgroundTask(data: newData) { data, completion in
                     print("Sende Daten: stickType=\(data.stickTypeRaw), angle=\(data.angleText)")
                     DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                         completion(true)
                     }
                 }
             }
         }
     }
 }

 // Vorschau
 struct ContentView_Previews: PreviewProvider {
     static var previews: some View {
         ContentView()
     }
 }
*/
