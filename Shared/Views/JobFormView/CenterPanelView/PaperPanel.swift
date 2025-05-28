//
//  PaperPanel.swift
//  Robart
//
//  Created by Carsten Nichte on 11.04.25.
//

// PaperPanel.swift
import SwiftUI
import SVGView
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import WebKit
import UniformTypeIdentifiers

private class RulerFormat{
    
    public var lenght:CGFloat
    public var width:CGFloat
    public var color:Color
    
    init(length:CGFloat, width:CGFloat, color:Color){
        self.lenght = length
        self.width = width
        self.color = color
    }
}

struct PaperPanel: View {
    @EnvironmentObject var model: SVGInspectorModel
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

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
                let pitchBinding = Binding<Double>(
                    get: { model.jobBox.pitch },
                    set: { newPitch in
                        model.jobBox.pitch = newPitch
                        model.syncJobBoxBack()
                    })

                // 2) Hintergrund-Papier mit Farbe, Rand und Schatten
                Rectangle()
                    .fill(Color(hex: model.job.paperData.color))
                    .frame(width: paperFrame.width, height: paperFrame.height)
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 5, y: 5)
                    .overlay(
                        Rectangle().stroke(Color.black, lineWidth: 0.5)
                    )

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
                .frame(width: paperFrame.width, height: rulerThickness) // TODO: Invalid frame dimension (negative or non-finite).
                .cornerRadius(0)
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                .offset(x: 0, y: -(paperFrame.height/2 + rulerThickness/2 + rulerGap))

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

                // 5) SVG-Inhalt mit Pan/Zoom/Rotate
                if isLoading {
                    ProgressView("SVG wird geladen…")
                        .progressViewStyle(.linear)
                        .frame(width: paperFrame.width)
                        .offset(x: 0, y: 0)
                } else if let svgURL = resolveSVGURL() {
                    WebView(fileURL: svgURL) { error in
                        if let error = error {// Modifying state during view update, this will cause undefined behavior.
                            print("WebView error: \(error)")
                        }
                    }
                    .scaleEffect(CGFloat(model.jobBox.zoom))
                    .rotationEffect(.degrees(model.jobBox.pitch))
                    .offset(x: model.jobBox.origin.x, y: model.jobBox.origin.y)
                    .frame(width: paperFrame.width, height: paperFrame.height)
                    .clipped()
                    .onAppear {
                        ensureFileIsDownloaded(url: svgURL)
                    }
                } else {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }

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
                        Slider(value: pitchBinding, in: 0...360)
                        TextField("", value: pitchBinding,
                                  format: .number.precision(.fractionLength(0)))
                            .frame(width: 50)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.5))
                .cornerRadius(8)
                .foregroundColor(.white)
                .offset(x: 0, y: paperFrame.height / 2 - 60)
                .opacity(0.8)
            }
            // Gesamt-Frame & Pan-Gesture
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { val in
                        model.jobBox.origin = CGPoint(x: val.translation.width,
                                                      y: val.translation.height)
                        model.syncJobBoxBack()
                    }
            )
            .onAppear {
                loadSVG()
            }
            .padding(EdgeInsets(top: 20, leading: 20, bottom: 40, trailing: 20)) // Rand um das Papier
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
struct WebView: UIViewControllerRepresentable {
    let fileURL: URL?
    let errorHandler: (String?) -> Void
    func makeUIViewController(context: Context) -> WebController {
        let controller = WebController()
        controller.fileURL = fileURL
        controller.errorHandler = errorHandler
        return controller
    }
    func updateUIViewController(_ uiViewController: WebController, context: Context) {
        uiViewController.loadSVG(fileURL: fileURL)
    }
}
class WebController: UIViewController, WKNavigationDelegate, UIGestureRecognizerDelegate {
    var webView: WKWebView!
    var fileURL: URL?
    var errorHandler: ((String?) -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = false // TODO: 'javaScriptEnabled' was deprecated in iOS 14.0: Use WKWebpagePreferences.allowsContentJavaScript to disable content JavaScript on a per-navigation basis
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.allowsAirPlayForMediaPlayback = false
        config.limitsNavigationsToAppBoundDomains = true
        config.suppressesIncrementalRendering = true
        webView = WKWebView(frame: view.bounds, configuration: config)
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
    }
    func loadSVG(fileURL: URL?) {
        guard let url = fileURL else {
            errorHandler?("No file selected")
            return
        }
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
    }
    func setupGestures() {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        [pinch, pan, rotation].forEach {
            $0.delegate = self
            webView.addGestureRecognizer($0)
        }
    }
    @objc func handlePinch(_ g: UIPinchGestureRecognizer) {
        guard let v = g.view else { return }
        if g.state == .changed { v.transform = v.transform.scaledBy(x: max(0.1,g.scale), y: max(0.1,g.scale)); g.scale = 1 }
    }
    @objc func handlePan(_ g: UIPanGestureRecognizer) {
        guard let v = g.view else { return }
        if g.state == .changed {
            let t = g.translation(in: v)
            v.transform = v.transform.translatedBy(x: t.x, y: t.y)
            g.setTranslation(.zero, in: v)
        }
    }
    @objc func handleRotation(_ g: UIRotationGestureRecognizer) {
        guard let v = g.view else { return }
        if g.state == .changed { v.transform = v.transform.rotated(by: g.rotation); g.rotation = 0 }
    }
    func webView(_ w: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        errorHandler?("Navigation error: \(error.localizedDescription)")
    }
    func webView(_ w: WKWebView, didFinish navigation: WKNavigation!) {}
}
#elseif canImport(AppKit)
struct WebView: NSViewControllerRepresentable {
    let fileURL: URL?
    let errorHandler: (String?) -> Void
    func makeNSViewController(context: Context) -> WebController {
        let c = WebController()
        c.fileURL = fileURL
        c.errorHandler = errorHandler
        return c
    }
    func updateNSViewController(_ nc: WebController, context: Context) {
        nc.loadSVG(fileURL: fileURL)
    }
}
class WebController: NSViewController, WKNavigationDelegate, NSGestureRecognizerDelegate {
    var webView: WKWebView!
    var fileURL: URL?
    var errorHandler: ((String?) -> Void)?
    override func loadView() {
        let cfg = WKWebViewConfiguration()
        cfg.preferences.javaScriptEnabled = false
        cfg.limitsNavigationsToAppBoundDomains = true
        webView = WKWebView(frame: .zero, configuration: cfg)
        webView.setValue(false, forKey: "drawsBackground")
        webView.wantsLayer = true
        webView.layer?.backgroundColor = NSColor.white.cgColor
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
            defer { secureURL.stopAccessingSecurityScopedResource() }
        }
        webView.loadFileURL(secureURL, allowingReadAccessTo: secureURL.deletingLastPathComponent())
    }
    func setupGestures() {
        let pan = NSPanGestureRecognizer(target: self, action: #selector(handlePan))
        let mag = NSMagnificationGestureRecognizer(target: self, action: #selector(handleMagnification))
        let rot = NSRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        [pan, mag, rot].forEach {
            $0.delegate = self
            webView.addGestureRecognizer($0)
        }
    }
    @objc func handlePan(_ g: NSPanGestureRecognizer) {
        guard let v = g.view else { return }
        let t = g.translation(in: v)
        v.setFrameOrigin(NSPoint(x: v.frame.origin.x + t.x, y: v.frame.origin.y + t.y))
        g.setTranslation(.zero, in: v)
    }
    @objc func handleMagnification(_ g: NSMagnificationGestureRecognizer) {
        guard let v = g.view else { return }
        v.setFrameSize(NSSize(width: v.frame.width * (1+g.magnification),
        height: v.frame.height * (1+g.magnification)))
        g.magnification = 0
    }
    @objc func handleRotation(_ g: NSRotationGestureRecognizer) {
        guard let v = g.view else { return }
        var t = v.layer?.transform ?? CATransform3DIdentity
        t = CATransform3DRotate(t, -g.rotation, 0, 0, 1)
        v.layer?.transform = t
        g.rotation = 0
    }
    func webView(_ w: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        errorHandler?("Error: \(error.localizedDescription)")
    }
    func webView(_ w: WKWebView, didFinish navigation: WKNavigation!) {}
}
#endif

// Hex-String → Color
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        if hex.count == 6 {
            (r, g, b) = ((int >> 16) & 0xFF,
                         (int >> 8)  & 0xFF,
                         int         & 0xFF)
        } else {
            (r, g, b) = (255, 255, 255)
        }
        self.init(
            red:   Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue:  Double(b) / 255.0)
    }
}
