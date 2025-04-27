//
//  TestView.swift
//  Robart
//
//  Created by Carsten Nichte on 27.04.25.
//

#if os(macOS)
import SwiftUI
import AppKit

// AppKit-basierter Splitter mit resizeLeftRight-Mauszeiger
struct ResizeSplitter1: NSViewRepresentable {
    @Binding var isDragging: Bool
    let onDrag: (CGFloat) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = CustomNSView(coordinator: context.coordinator)
        view.wantsLayer = true
        // Grundfarbe für den Splitter: Anthrazit
        view.layer?.backgroundColor = isDragging ? NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.4).cgColor : NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.1).cgColor
        
        // Gesture-Recognizer hinzufügen
        let panGesture = NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:)))
        view.addGestureRecognizer(panGesture)
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Farbe aktualisieren: Anthrazit
        nsView.layer?.backgroundColor = isDragging ? NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.4).cgColor : NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.1).cgColor
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isDragging: $isDragging, onDrag: onDrag)
    }
    
    class Coordinator: NSObject {
        @Binding var isDragging: Bool
        let onDrag: (CGFloat) -> Void
        private var initialTranslation: CGFloat = 0
        
        init(isDragging: Binding<Bool>, onDrag: @escaping (CGFloat) -> Void) {
            self._isDragging = isDragging
            self.onDrag = onDrag
            super.init()
        }
        
        @objc func handleDrag(_ gesture: NSPanGestureRecognizer) {
            switch gesture.state {
            case .began:
                isDragging = true
                initialTranslation = gesture.translation(in: gesture.view).x
            case .changed:
                let currentTranslation = gesture.translation(in: gesture.view).x
                let delta = currentTranslation - initialTranslation
                onDrag(-delta) // Negativ, da Bewegung nach links die Breite erhöht
                initialTranslation = currentTranslation
            case .ended, .cancelled:
                isDragging = false
                initialTranslation = 0
            default:
                break
            }
        }
        
        func mouseEntered(with event: NSEvent) {
            NSCursor.resizeLeftRight.push()
        }
        
        func mouseExited(with event: NSEvent) {
            NSCursor.pop()
        }
    }
    
    class CustomNSView: NSView {
        private let coordinator: Coordinator
        
        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(frame: .zero)
            
            // Mauszeiger hinzufügen
            let trackingArea = NSTrackingArea(
                rect: .zero,
                options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(trackingArea)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func mouseEntered(with event: NSEvent) {
            coordinator.mouseEntered(with: event)
        }
        
        override func mouseExited(with event: NSEvent) {
            coordinator.mouseExited(with: event)
        }
        
        override func updateTrackingAreas() {
            trackingAreas.forEach { removeTrackingArea($0) }
            let trackingArea = NSTrackingArea(
                rect: .zero,
                options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(trackingArea)
            super.updateTrackingAreas()
        }
        
        // 3D-Effekt durch eine dünne innere Linie simulieren
        override func draw(_ dirtyRect: NSRect) {
            super.draw(dirtyRect)
            
            // Zeichne eine dunkle Linie auf der linken Seite für den 3D-Effekt (stärkerer Schatten)
            let linePath = NSBezierPath()
            linePath.move(to: NSPoint(x: bounds.width / 2 - 1.0, y: 0))
            linePath.line(to: NSPoint(x: bounds.width / 2 - 1.0, y: bounds.height))
            NSColor.black.withAlphaComponent(0.5).setStroke()
            linePath.lineWidth = 1
            linePath.stroke()
            
            // Helle Kante auf der rechten Seite für den 3D-Effekt
            let highlightPath = NSBezierPath()
            highlightPath.move(to: NSPoint(x: bounds.width / 2 + 1.0, y: 0))
            highlightPath.line(to: NSPoint(x: bounds.width / 2 + 1.0, y: bounds.height))
            NSColor.white.withAlphaComponent(0.1).setStroke()
            highlightPath.lineWidth = 1
            highlightPath.stroke()
        }
    }
    
    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        nsView.trackingAreas.forEach { nsView.removeTrackingArea($0) }
        nsView.gestureRecognizers.forEach { nsView.removeGestureRecognizer($0) }
    }
}

struct TestView: View {
    @State private var isNavigatorVisible = true
    @State private var isInspectorVisible = true
    @State private var inspectorWidth: CGFloat = 250 // Standardbreite des Inspektors
    @State private var isDragging = false // Zustand für Drag-Interaktion
    
    var body: some View {
        NavigationSplitView {
            // Navigator (linker Bereich)
            if isNavigatorVisible {
                VStack {
                    Text("Navigator")
                        .font(.title)
                    List {
                        Text("Item 1")
                        Text("Item 2")
                        Text("Item 3")
                    }
                    Button("Toggle Navigator") {
                        withAnimation {
                            isNavigatorVisible.toggle()
                        }
                    }
                }
                .frame(minWidth: 200, idealWidth: 250)
            } else {
                // Platzhalter, wenn Navigator ausgeblendet
                Text("Navigator ausgeblendet")
                    .frame(minWidth: 50)
            }
        } detail: {
            // Hauptinhalt und Inspektor
            HStack(spacing: 0) {
                // Hauptinhalt
                VStack {
                    Text("Hauptinhalt")
                        .font(.largeTitle)
                    // Nur Navigator-Button im Hauptbereich
                    Button("Navigator \(isNavigatorVisible ? "Ausblenden" : "Einblenden")") {
                        withAnimation {
                            isNavigatorVisible.toggle()
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Benutzerdefinierter Splitter mit AppKit
                if isInspectorVisible {
                    ResizeSplitter1(isDragging: $isDragging) { translation in
                        isDragging = true
                        let newWidth = inspectorWidth + translation // Positiv, da translation die Änderung repräsentiert
                        inspectorWidth = min(max(newWidth, 150), 400)
                        print("Inspektor-Breite: \(inspectorWidth)")
                    }
                    .frame(width: 4) // Etwa 1 mm breiter (von 2 auf 4 Pixel)
                }
                
                // Inspektor (rechter Bereich)
                if isInspectorVisible {
                    VStack {
                        Text("Inspektor")
                            .font(.title)
                        Form {
                            TextField("Einstellung", text: .constant(""))
                            Toggle("Option", isOn: .constant(true))
                        }
                        Button("Toggle Inspektor") {
                            withAnimation {
                                isInspectorVisible.toggle()
                            }
                        }
                    }
                    .frame(width: inspectorWidth) // Dynamische Breite
                    // .background(Color(.systemGroupedBackground))
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .toolbar {
            // Toolbar-Items für Inspektor
            ToolbarItem(placement: .automatic) {
                Button(action: {
                    withAnimation {
                        isInspectorVisible.toggle()
                    }
                }) {
                    Label(
                        isInspectorVisible ? "Inspektor ausblenden" : "Inspektor einblenden",
                        systemImage: "sidebar.right"
                    )
                    .foregroundColor(isInspectorVisible ? .accentColor : .gray)
                }
            }
        }
    }
}

struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
#endif
