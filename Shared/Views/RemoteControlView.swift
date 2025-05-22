//
//  RemoteControlView.swift
//  Drawingbot-RobArt
//
//  Created by Carsten Nichte on 08.04.25.
//


// RemoteControlView.swift
import SwiftUI

// MARK: - RemoteControlView

public struct RemoteControlView: View {
    // TODO: use AssetStore for settings
    @AppStorage("currentLeftStickType") private var currentLeftStickType: String = RemoteControlStickType.standard.rawValue
    @AppStorage("currentRightStickType") private var currentRightStickType: String = RemoteControlStickType.standard.rawValue
    @AppStorage("currentLeftStickMode") private var currentLeftStickMode: String = RemoteControlStickMode.free.rawValue
    @AppStorage("currentRightStickMode") private var currentRightStickMode: String = RemoteControlStickMode.free.rawValue
    
    @EnvironmentObject var bluetoothManager: BluetoothManager
    
    @StateObject private var leftStickValues = StickValues.default
    @StateObject private var rightStickValues = StickValues.default
    @StateObject private var backgroundTask: BackgroundTaskManager<CombinedStickValues> = BackgroundTaskManager()
    
    public var body: some View {
        VStack(spacing: 15) {
            joystickToolbarView
            HStack {
                Speedometer_View(stickValues: leftStickValues) // left Stick
                Spacer()
                Speedometer_View(stickValues: rightStickValues) // right Stick
            }
            .padding()
            
            Spacer()
            
            HStack(alignment: .top, spacing: 50) {
                Joystick_View(stickValues: leftStickValues)
                Joystick_View(stickValues: rightStickValues)
            }
        }
        .padding()
        .navigationTitle("Fernsteuerung")
        .onAppear {
            // Initialisiere stickValues mit AppStorage-Werten
            leftStickValues.stickTypeRaw = currentLeftStickType
            leftStickValues.stickModeRaw = currentLeftStickMode
            rightStickValues.stickTypeRaw = currentRightStickType
            rightStickValues.stickModeRaw = currentRightStickMode
        }
        
        .onChange(of: currentLeftStickType) { _, newValue in
            leftStickValues.stickTypeRaw = newValue
        }
        .onChange(of: currentLeftStickMode) { _, newValue in
            leftStickValues.stickModeRaw = newValue
        }
        .onChange(of: currentRightStickType) { _, newValue in
            rightStickValues.stickTypeRaw = newValue
        }
        .onChange(of: currentRightStickMode) { _, newValue in
            rightStickValues.stickModeRaw = newValue
        }
        
        .onReceive(leftStickValues.objectWillChange) { _ in
            let newCombined = CombinedStickValues(left: leftStickValues.clone(), right: rightStickValues.clone())
            backgroundTask.updateData(newCombined)
        }
        .onReceive(rightStickValues.objectWillChange) { _ in
            let newCombined = CombinedStickValues(left: leftStickValues.clone(), right: rightStickValues.clone())
            backgroundTask.updateData(newCombined)
        }
    }
    
    // MARK: - joystickToolbarView
    
    private var joystickToolbarView: some View {
        CollapsibleSection(title: "Joystick", systemImage: "gamecontroller.fill", toolbar: {
            Text(backgroundTask.isRunning ? "runs" : "stopped")
                .font(.headline)
                .foregroundColor(backgroundTask.isRunning ? .green : .red)
            
            CustomToolbarButton(
                title: (backgroundTask.isRunning ? "Task stop" : "Task start"),
                icon: "paperplane.fill",
                style: .primary,
                role: nil,
                hasBorder: false,
                iconSize: .large
            ) {
                if backgroundTask.isRunning {
                    backgroundTask.stopBackgroundTask()
                } else {
                    backgroundTask.startBackgroundTask { data, completion in
                        // appLog(.error, "Sende Daten: \(data.toString())")
                        // TODO: use MachineCommandResolver and templates: "G1 X{X} Y{Y} R{R}"
                        Task {
                            let command_string = String(format: "G1 X%.1f Y%.1f R%.2f\n", data.left.position.x, data.left.position.y, data.right.rotation)
                            appLog(.error, "Sende Command: \(command_string)")
                            bluetoothManager.send("\(command_string)")
                        }
                    }
                }
            }
        }) {
            
            
            HStack {
                Text("LeftStick Type")
                Picker("LeftStick Type", selection: $currentLeftStickType) {
                    Text(".standard").tag(RemoteControlStickType.standard.rawValue)
                    Text(".rotate").tag(RemoteControlStickType.rotate.rawValue)
                }
                .pickerStyle(.segmented)
            }
            
            HStack {
                Text("RightStick Type")
                Picker("RightStick Type", selection: $currentRightStickType) {
                    Text(".standard").tag(RemoteControlStickType.standard.rawValue)
                    Text(".rotate").tag(RemoteControlStickType.rotate.rawValue)
                }
                .pickerStyle(.segmented)
            }
            
        }
    }
}
