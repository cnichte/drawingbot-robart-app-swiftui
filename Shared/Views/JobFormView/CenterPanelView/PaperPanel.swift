//
//  PaperPanel.swift
//  Robart
//
//  Created by Carsten Nichte on 11.04.25.
//

// PaperPanel.swift
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import WebKit
import UniformTypeIdentifiers

// MARK: - RulerFormat
private class RulerFormat {
    
    public var lenght:CGFloat
    public var width:CGFloat
    public var color:Color
    
    init(length:CGFloat, width:CGFloat, color:Color){
        self.lenght = length
        self.width = width
        self.color = color
    }
}

// MARK: - PaperPanel
struct PaperPanel: View {
    @EnvironmentObject var model: SVGInspectorModel
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var initialDragOrigin: CGPoint = .zero
    

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 1) Papier-Orientierung & Maßstab
                let isLandscape = model.job.paperOrientation == .landscape
                let widthUnits  = isLandscape
                    ? model.job.paperData.paperFormat.height
                    : model.job.paperData.paperFormat.width
                let heightUnits = isLandscape
                    ? model.job.paperData.paperFormat.width
                    : model.job.paperData.paperFormat.height

                let paperSize    = CGSize(width: CGFloat(widthUnits), height: CGFloat(heightUnits))
                // Account for panel padding and top ruler
                let rulerThickness: CGFloat = 20
                let rulerGap: CGFloat = 5
                let horizontalPadding: CGFloat = 20 + 20  // leading + trailing
                let verticalPadding: CGFloat = 20 + 40 + rulerThickness + rulerGap // top + bottom + top ruler + gap
                let availableWidth = geo.size.width - horizontalPadding
                let availableHeight = geo.size.height - verticalPadding

                // Compute scale factor safely, avoiding negative or non-finite values
                let rawScaleX = paperSize.width > 0 ? availableWidth / paperSize.width : .infinity
                let rawScaleY = paperSize.height > 0 ? availableHeight / paperSize.height : .infinity
                let rawScale = min(rawScaleX, rawScaleY)
                // Use 1.0 if result is non-finite or non-positive
                let scaleFactor = (rawScale.isFinite && rawScale > 0) ? rawScale : 1.0
                // Ensure frame dimensions are non-negative
                let paperFrame = CGSize(
                    width: max(0, paperSize.width * scaleFactor),
                    height: max(0, paperSize.height * scaleFactor)
                )
                
                let unitsLabel  = model.job.paperData.paperFormat.unit.name
                let unitsFactor = model.job.paperData.paperFormat.unit.factor
                
                // RulerFormat
                let shortRF:RulerFormat = RulerFormat(length: 5.0, width: 0.5, color: .white);
                let longRF:RulerFormat  = RulerFormat(length: 7.5, width: 1.0, color: .red);
                
                // ruler configuration
                // let rulerThickness: CGFloat = 20
                // let rulerGap: CGFloat = 5

                // Bindings über JobBox
                let zoomBinding = Binding<Double>(
                    get: { model.jobBox.zoom },
                    set: { newZoom in
                        model.jobBox.zoom = newZoom
                        model.syncJobBoxBack()
                    })
                let angleBinding = Binding<Double>(
                    get: { model.jobBox.angle },
                    set: { newAngle in
                        model.jobBox.angle = newAngle
                        model.syncJobBoxBack()
                    })

                // MARK: - PaperPanel: Hintergrund-Papier
                // 2) Hintergrund-Papier mit Farbe, Rand und Schatten
                Rectangle()
                    .fill(Color(hex: model.job.paperData.color))
                    .frame(width: paperFrame.width, height: paperFrame.height)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 5, y: 5)
                    .overlay(
                        Rectangle().stroke(Color.black, lineWidth: 0.5)
                    )

                // MARK: - PaperPanel: Ruler oben
                // 3) Ruler oben
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    Canvas { context, size in
                        for i in stride(from: 0.0, through: widthUnits, by: 10.0) {
                            let x = CGFloat(i) * scaleFactor
                            var tick = Path()
                            let h: CGFloat = (i.truncatingRemainder(dividingBy: 50) == 0) ? longRF.lenght : shortRF.lenght
                            tick.move(to: CGPoint(x: x, y: size.height))
                            tick.addLine(to: CGPoint(x: x, y: size.height - h))
                            
                            if(h == longRF.lenght){
                                context.stroke(tick, with: .color(longRF.color), lineWidth: longRF.width)
                            }else{
                                context.stroke(tick, with: .color(shortRF.color), lineWidth: shortRF.width)
                            }
                            
                            if i.truncatingRemainder(dividingBy: 50) == 0 {
                                let txt = Text("\(Int(i))") // \(unitsLabel)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                context.draw(txt,
                                             at: CGPoint(x: x + 2, y: size.height * 0.9),
                                             anchor: .bottomLeading)
                            }
                        }
                    }
                }
                .frame(width: paperFrame.width, height: rulerThickness)
                .cornerRadius(0)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .offset(x: 0, y: -(paperFrame.height/2 + rulerThickness/2 + rulerGap))

                // MARK: - PaperPanel: Ruler links
                // 4) Ruler links
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    Canvas { context, size in
                        for i in stride(from: 0.0, through: heightUnits, by: 10.0) {
                            let y = CGFloat(i) * scaleFactor
                            var tick = Path()
                            let w: CGFloat = (i.truncatingRemainder(dividingBy: 50) == 0) ? longRF.lenght : shortRF.lenght
                            tick.move(to: CGPoint(x: size.width, y: y))
                            tick.addLine(to: CGPoint(x: size.width - w, y: y))
                            
                            if(w == longRF.lenght){
                                context.stroke(tick, with: .color(longRF.color), lineWidth: longRF.width)
                            }else{
                                context.stroke(tick, with: .color(shortRF.color), lineWidth: shortRF.width)
                            }
                            
                            if i.truncatingRemainder(dividingBy: 50) == 0 {
                                let txt = Text("\(Int(i))") // \(unitsLabel)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                context.draw(txt,
                                             at: CGPoint(x: size.width * 0.9, y: y + 2),
                                             anchor: .topTrailing)
                            }
                        }
                    }
                }
                .frame(width: rulerThickness, height: paperFrame.height)
                .cornerRadius(0)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .offset(x: -(paperFrame.width/2 + rulerThickness/2 + rulerGap), y: 0)

                // MARK: - PaperPanel: Progress & WebView
                // 5) SVG-Inhalt mit Pan/Zoom/Rotate
                if isLoading {
                    ProgressView("SVG wird geladen…")
                        .progressViewStyle(.linear)
                        .frame(width: paperFrame.width)
                        .offset(x: 0, y: 0)
                } else if let svgURL = resolveSVGURL() {
                    Group {
                        #if canImport(UIKit)
                        WebView(fileURL: svgURL) { error in
                            if let error = error { print("WebView error: \(error)") }
                        }
                        #elseif canImport(AppKit)
                        WebView(fileURL: svgURL,
                                zoom: model.jobBox.zoom,
                                angle: model.jobBox.angle) { error in
                            if let error = error { print("WebView error: \(error)") }
                        }
                        #endif
                    }
                    .frame(width: paperFrame.width, height: paperFrame.height)
                    .border(Color.green) // TODO: DEBUG
                    .clipped()
                    .onAppear { ensureFileIsDownloaded(url: svgURL) }
                } else {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                // MARK: - PaperPanel: Overlay-Steuerung
                // 6) Overlay-Steuerung (Zoom + Drehung)
                VStack(spacing: 8) {
                    HStack {
                        Text("Zoom:")
                        Slider(value: zoomBinding, in: 0.05...2.0)
                        TextField("", value: zoomBinding,
                                  format: .number.precision(.fractionLength(2)))
                            .frame(width: 50)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    HStack {
                        Text("Drehung:")
                        Slider(value: angleBinding, in: 0...360)
                        TextField("", value: angleBinding,
                                  format: .number.precision(.fractionLength(0)))
                            .frame(width: 50)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                     .padding()
                    
                }
                .padding(8)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
                .foregroundColor(.white)
                .offset(x: 0, y: paperFrame.height / 2 - 60)
                .opacity(0.8)
            }
            // MARK: - PaperPanel: Gesamt-Frame & Pan-Gesture
            // Gesamt-Frame & Pan-Gesture
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                loadSVG()
            }
            .padding(EdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)) // Rand um das Papier
        }
    }

    private func loadSVG() {
        guard let url = resolveSVGURL() else { return }
        isLoading = true
        Task {
            _ = try? Data(contentsOf: url)
            await MainActor.run {
                isLoading = false
            }
        }
    }

    // MARK: - Helpers
    private func resolveSVGURL() -> URL? {
        guard !model.job.svgFilePath.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }
        do {
            let docs = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil, create: false)
            let full = docs.appendingPathComponent(model.job.svgFilePath)
            return FileManager.default.fileExists(atPath: full.path) ? full : nil
        } catch {
            appLog(.info, "❌ Fehler beim Documents-Pfad: \(error)")
            return nil
        }
    }

    private func ensureFileIsDownloaded(url: URL) {
        do {
            let vals = try url.resourceValues(forKeys: [.isUbiquitousItemKey])
            if vals.isUbiquitousItem == true {
                try FileManager.default.startDownloadingUbiquitousItem(at: url)
                appLog(.info, "📥 Download gestartet: \(url.lastPathComponent)")
            }
        } catch {
            appLog(.info, "⚠️ Download-Check-Fehler: \(error)")
        }
    }
}

#if canImport(UIKit)
// MARK: - DocumentPicker (UIKit, iOS)
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileURL: URL?
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.svg])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: DocumentPicker
        init(_ parent: DocumentPicker) { self.parent = parent }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            DispatchQueue.main.async { self.parent.fileURL = url }
        }
    }
}

// MARK: - WebView (UIKit, iOS)
struct WebView: UIViewControllerRepresentable {
    @EnvironmentObject var model: SVGInspectorModel
    let fileURL: URL?
    let errorHandler: (String?) -> Void
    func makeUIViewController(context: Context) -> WebController {
        let controller = WebController()
        controller.fileURL = fileURL
        controller.errorHandler = errorHandler
        controller.model = model
        return controller
    }
    func updateUIViewController(_ uiViewController: WebController, context: Context) {
        uiViewController.loadSVG(fileURL: fileURL)
        uiViewController.applyModelTransforms()
    }
}

// MARK: - WebController (UIKit, iOS)
class WebController: UIViewController, WKNavigationDelegate, UIGestureRecognizerDelegate {
    var webView: WKWebView!
    var fileURL: URL?
    var errorHandler: ((String?) -> Void)?
    var model: SVGInspectorModel!
    override func viewDidLoad() {
        super.viewDidLoad()
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = false // TODO: 'javaScriptEnabled' was deprecated in iOS 14.0: Use WKWebpagePreferences.allowsContentJavaScript to disable content JavaScript on a per-navigation basis
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.allowsAirPlayForMediaPlayback = false
        config.limitsNavigationsToAppBoundDomains = true
        config.suppressesIncrementalRendering = true
        webView = WKWebView(frame: view.bounds, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.navigationDelegate = self
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.bounces = false
        setupGestures()
        applyModelTransforms()
    }
    func loadSVG(fileURL: URL?) {
        guard let url = fileURL else {
            errorHandler?("No file selected")
            return
        }
        do {
            let svgData = try Data(contentsOf: url)
            guard let svgString = String(data: svgData, encoding: .utf8) else {
                errorHandler?("Unable to read SVG")
                return
            }
            
            // Passe die SVG-Größe proportional an das Papier an (mit Seitenverhältnis)
            // TODO: Das muss eigentlich nur ein einziges mal passieren (im SVGSectionView), wenn das SVG das erste mal geladen wird! Die Info ist ja konstant und kann im job! (nicht nur im model, das ist nicht persistent) despeichert werden.
            model.caluclateSVGSizeFromPaper()
            
            let svgWidthString = model.svgWidthString;
            let svgHeightString = model.svgHeightString;
        
            let htmlString = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    html, body {  margin:0; padding:0; overflow:hidden; background-color:transparent; } 
                    svg { width: \(svgWidthString); height:\(svgHeightString); background-color: transparent; }
                </style>
            </head>
            <body>
            \(svgString)
            </body>
            </html>
            """
            
            webView.loadHTMLString(htmlString, baseURL: url.deletingLastPathComponent())
        } catch {
            errorHandler?("Error loading SVG: \(error.localizedDescription)")
        }
    }
    func webView(_ w: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        errorHandler?("Navigation error: \(error.localizedDescription)")
    }
    func webView(_ w: WKWebView, didFinish navigation: WKNavigation!) {
        // applyModelTransforms()
    }

    func applyModelTransforms() {
        let o = model.jobBox.origin
        let z = CGFloat(model.jobBox.zoom)
        let a = CGFloat(model.jobBox.angle * .pi/180)
        var t = CGAffineTransform.identity
        t = t.translatedBy(x: o.x, y: o.y)
        t = t.scaledBy(x: z, y: z)
        t = t.rotated(by: a)
        webView.transform = t
    }

    private func setupGestures() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        webView.addGestureRecognizer(pan)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        webView.addGestureRecognizer(pinch)
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotation.delegate = self
        webView.addGestureRecognizer(rotation)
    }
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: webView.superview)
        if gesture.state == .began {
            // Store initial origin if needed
        }
        if gesture.state == .changed || gesture.state == .ended {
            let newOrigin = CGPoint(
                x: model.jobBox.origin.x + translation.x,
                y: model.jobBox.origin.y + translation.y
            )
            model.jobBox.origin = newOrigin
            if gesture.state == .ended {
                // Optionally sync back if needed
            }
            // Assign back to model and apply transforms
            applyModelTransforms()
        }
        gesture.setTranslation(.zero, in: webView.superview)
    }
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed || gesture.state == .ended {
            let newZoom = model.jobBox.zoom * Double(gesture.scale)
            model.jobBox.zoom = newZoom
            if gesture.state == .ended {
                // Optionally sync back if needed
            }
            applyModelTransforms()
            gesture.scale = 1.0
        }
    }
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        if gesture.state == .changed || gesture.state == .ended {
            let newAngle = model.jobBox.angle + Double(gesture.rotation * 180 / .pi)
            model.jobBox.angle = newAngle
            if gesture.state == .ended {
                // Optionally sync back if needed
            }
            applyModelTransforms()
            gesture.rotation = 0
        }
    }
}
#elseif canImport(AppKit)
// MARK: - AppKit WebView (AppKit, macOS)
struct WebView: NSViewControllerRepresentable {
    @EnvironmentObject var model: SVGInspectorModel
    let fileURL: URL?
    let zoom: Double
    let angle: Double
    let errorHandler: (String?) -> Void
    func makeNSViewController(context: Context) -> WebController {
        let c = WebController()
        c.fileURL = fileURL
        c.errorHandler = errorHandler
        c.model = model
        return c
    }
    func updateNSViewController(_ nc: WebController, context: Context) {
        nc.loadSVG(fileURL: fileURL)
        nc.applyModelTransforms()
    }
}
// MARK: - WebController (AppKit, macOS)
class WebController: NSViewController, WKNavigationDelegate, NSGestureRecognizerDelegate {
    var webView: WKWebView!
    var fileURL: URL?
    var errorHandler: ((String?) -> Void)?
    var model: SVGInspectorModel!
    override func loadView() {
        let cfg = WKWebViewConfiguration()
        // cfg.preferences.javaScriptEnabled = false // TODO: 'javaScriptEnabled' was deprecated in macOS 11.0: Use WKWebpagePreferences.allowsContentJavaScript to disable content JavaScript on a per-navigation basis
        cfg.limitsNavigationsToAppBoundDomains = true
        webView = WKWebView(frame: .zero, configuration: cfg)
        webView.setValue(false, forKey: "drawsBackground")
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.blue.cgColor // TODO: Testweise auf blue gesetzt
        webView.navigationDelegate = self
        view = webView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        if let scrollView = webView.enclosingScrollView {
            scrollView.hasHorizontalScroller = false
            scrollView.hasVerticalScroller = false
            scrollView.autohidesScrollers = true
            scrollView.borderType = .noBorder
        }
        setupGestures()
        applyModelTransforms()
    }
    func loadSVG(fileURL: URL?) {
        guard let url = fileURL else {
            errorHandler?("No file selected")
            return
        }
        var secureURL = url
        if let data = UserDefaults.standard.data(forKey: "svgBookmark_\(url.path)") {
            var isStale = false
            if let resolved = try? URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale),
               !isStale {
                secureURL = resolved
            }
        }
        if secureURL.startAccessingSecurityScopedResource() {
            do { secureURL.stopAccessingSecurityScopedResource() }
        }
        do {
            let svgData = try Data(contentsOf: secureURL)
            guard let svgString = String(data: svgData, encoding: .utf8) else {
                errorHandler?("Unable to read SVG")
                return
            }
            
            // Passe die SVG-Größe proportional an das Papier an (mit Seitenverhältnis)
            // TODO: Das muss eigentlich nur ein einziges mal passieren (im SVGSectionView), wenn das SVG das erste mal geladen wird! Die Info ist ja konstant und kann im job! (nicht nur im model, das ist nicht persistent) despeichert werden.
            model.caluclateSVGSizeFromPaper()
            
            let svgWidthString = model.svgWidthString;
            let svgHeightString = model.svgHeightString;
            
            let htmlString = """
            <!DOCTYPE html>
            <html>
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    html, body { 
                        margin: 0; 
                        padding: 0; 
                        overflow: hidden; 
                        background-color: transparent;
                    }
                    svg {
                        display: block;
                        margin: auto;
                        width: \(svgWidthString);
                        height:\(svgHeightString);
                        background-color: green;
                    }
                </style>
            </head>
            <body>
            \(svgString)
            </body>
            </html>
            """

            webView.loadHTMLString(htmlString, baseURL: secureURL.deletingLastPathComponent())
        } catch {
            errorHandler?("Error loading SVG: \(error.localizedDescription)")
        }
    }
    func webView(_ w: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        errorHandler?("Error: \(error.localizedDescription)")
    }
    func webView(_ w: WKWebView, didFinish navigation: WKNavigation!) {
        // Nach dem Laden des SVGs direkt die gespeicherten Transform-Werte anwenden
        applyModelTransforms()
    }

    func applyModelTransforms() {
        let o = model.jobBox.origin
        let z = CGFloat(model.jobBox.zoom)
        let a = CGFloat(model.jobBox.angle * .pi/180)
        webView.layer?.anchorPoint = CGPoint(x:0.5,y:0.5)
        var t = CATransform3DIdentity
        t = CATransform3DTranslate(t, o.x, o.y, 0)
        t = CATransform3DScale(t, z, z, 1)
        t = CATransform3DRotate(t, a, 0, 0, 1)
        webView.layer?.transform = t
    }

    private func setupGestures() {
        let pan = NSPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        webView.addGestureRecognizer(pan)
        let mag = NSMagnificationGestureRecognizer(target: self, action: #selector(handleMagnification(_:)))
        mag.delegate = self
        webView.addGestureRecognizer(mag)
        let rot = NSRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rot.delegate = self
        webView.addGestureRecognizer(rot)
    }
    @objc private func handlePan(_ gesture: NSPanGestureRecognizer) {
        let translation = gesture.translation(in: webView)
        if gesture.state == .began {
            // Optionally store initial origin
        }
        if gesture.state == .changed || gesture.state == .ended {
            let newOrigin = CGPoint(
                x: model.jobBox.origin.x + translation.x,
                y: model.jobBox.origin.y - translation.y
            )
            model.jobBox.origin = newOrigin
            if gesture.state == .ended {
                // Optionally sync back if needed
            }
            applyModelTransforms()
            gesture.setTranslation(.zero, in: webView)
        }
    }
    @objc private func handleMagnification(_ gesture: NSMagnificationGestureRecognizer) {
        if gesture.state == .changed || gesture.state == .ended {
            let newZoom = model.jobBox.zoom * Double(1 + gesture.magnification)
            model.jobBox.zoom = newZoom
            if gesture.state == .ended {
                // Optionally sync back if needed
            }
            applyModelTransforms()
            gesture.magnification = 0
        }
    }
    @objc private func handleRotation(_ gesture: NSRotationGestureRecognizer) {
        if gesture.state == .changed || gesture.state == .ended {
            let newAngle = model.jobBox.angle + Double(gesture.rotation * 180 / .pi)
            model.jobBox.angle = newAngle
            if gesture.state == .ended {
                // Optionally sync back if needed
            }
            applyModelTransforms()
            gesture.rotation = 0
        }
    }
}
#endif
