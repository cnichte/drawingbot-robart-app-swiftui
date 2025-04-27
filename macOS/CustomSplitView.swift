//
//  CustomSplitView.swift
//  Robart
//
//  Created by Carsten Nichte on 27.04.25.
//

// CustomSplitView.swift
#if os(macOS)
import SwiftUI
import AppKit
    
// AppKit-basierter Splitter für die Trennung zwischen Center und Right View
struct ResizeSplitter: NSViewRepresentable {
    @Binding var isDragging: Bool
    let onDrag: (CGFloat) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = CustomNSView(coordinator: context.coordinator)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.darkGray.withAlphaComponent(isDragging ? 0.4 : 0.1).cgColor
        
        let panGesture = NSPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDrag(_:)))
        view.addGestureRecognizer(panGesture)
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.layer?.backgroundColor = NSColor.darkGray.withAlphaComponent(isDragging ? 0.4 : 0.1).cgColor
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
                onDrag(-delta)
                initialTranslation = currentTranslation
            case .ended, .cancelled:
                isDragging = false
                initialTranslation = 0
            default:
                break
            }
        }
        
        func mouseEntered(with event: NSEvent) { NSCursor.resizeLeftRight.push() }
        func mouseExited(with event: NSEvent) { NSCursor.pop() }
    }
    
    class CustomNSView: NSView {
        private let coordinator: Coordinator
        
        init(coordinator: Coordinator) {
            self.coordinator = coordinator
            super.init(frame: .zero)
            
            let trackingArea = NSTrackingArea(
                rect: .zero,
                options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self,
                userInfo: nil
            )
            addTrackingArea(trackingArea)
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        
        override func mouseEntered(with event: NSEvent) { coordinator.mouseEntered(with: event) }
        override func mouseExited(with event: NSEvent) { coordinator.mouseExited(with: event) }
        
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
    }
}

// MARK: - Wiederverwendbare SplitView

struct CustomSplitView<Left: View, Center: View, Right: View>: View {
    @Binding var isLeftVisible: Bool
    @Binding var isRightVisible: Bool
    @Binding var rightPanelWidth: CGFloat
    
    @State private var isDragging = false
    
    let leftView: () -> Left
    let centerView: () -> Center
    let rightView: () -> Right
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Panel
            if isLeftVisible {
                leftView()
                    .frame(minWidth: 200, idealWidth: 250, maxWidth: 350)
                    // HINTERGRUND ENTFERNT!
                    .transition(.move(edge: .leading))
            }
            
            // Center Panel
            centerView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            
            // Resizable Splitter and Right Panel
            if isRightVisible {
                ResizeSplitter(isDragging: $isDragging) { translation in
                    let newWidth = rightPanelWidth + translation
                    rightPanelWidth = min(max(newWidth, 150), 500)
                }
                .frame(width: 4)
                .background(Color.gray.opacity(0.2))
                
                rightView()
                    .frame(width: rightPanelWidth)
                    // HINTERGRUND ENTFERNT!
                    .transition(.move(edge: .trailing))
            }
        }
    }
}
#endif
