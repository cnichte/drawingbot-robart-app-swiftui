# Anleitung: HatchFillManager.swift

Erweitere SVGParser so, das er geschlossene Pfade erkennt und HatchFill anwendet.
Basierend auf was? der Farbe?
Den vorgegebenen
Per zufallsgenerator?


Erweitere SVGParser so, das er auch mit dem  SVG `<pattern>`-Element umgehen kann, (und ggfs. den HatchFillManager anwendet?)

Benutze 
ParserListItem
private(set) var elements: [ParserListItem] = []

um die Ergebnisse ab zu speichern.
    
Der Übersichtlickeit halber können wir den neuen Code das in eine eigene Klasse SVGPatternElemetParser auslagern, der die im SVG Parser benutzt wird.
Auch hier sollen die Änderungen in einer neuen -preview svg datei gespeichert werden.


## 1. Übersicht  

`HatchFillManager` liest eine SVG-Datei ein, füllt sie mit verschiedenen Hatch-Mustern und liefert drei Ausgaben: 

- **Preview-SVG** (Datei mit Suffix `-preview.svg`)  
- **G-Code** (Array von Strings)  
- **EggCode** (Array von Strings)  

Unterstützte Hatch-Algorithmen: 
 
- Pattern-Based  
- Contour-Following  
- Stippling  
- Line-Based  
- Grid-Based  

## 2. Einbinden ins Projekt  

1. Kopiere `HatchFillManager.swift` in Deinen Xcode-Projektordner.  
2. Stelle sicher, dass folgende Dateien/Module verfügbar sind:  
   - `BasePlotterGenerator.swift`  
   - `SVGParser.swift`  
   - `GCodeGenerator.swift`  
   - `EggbotGenerator.swift`  
   - `PathParser.swift`  

## 3. Beispielnutzung

```swift
import Foundation

// 1. Pfad zur Quelldatei
let svgURL = URL(fileURLWithPath: "/Pfad/zur/Datei/meineGrafik.svg")

// 2. Manager erzeugen
let manager = HatchFillManager()

// 3. Verarbeiten mit gewünschtem Algorithmus und Parametern
let (previewURL, gcode, eggcode) = manager.process(
    inputURL: svgURL,
    hatchType: .lineBased,
    spacing: 10.0,
    svgSize: (width: 200.0, height: 100.0),
    paperSize: (width: 200.0, height: 100.0)
)

// 4. Ergebnisse prüfen
print("Preview-SVG gespeichert unter:", previewURL.path)
print("G-Code-Zeilen:", gcode.count)
print("EggCode-Zeilen:", eggcode.count)
```

## 4. Parameter

- hatchType: Wähle den gewünschten Füllstil
- spacing: Abstand zwischen Linien oder Punktepaaren
- svgSize: Original-SVG-Viewport (Breite, Höhe)
- paperSize: Ziel-Papiermaß für Skalierung


## 5. Anpassungen & Erweiterungen

- Contour-Following: Aktuell als Platzhalter (lineBased mit halbiertem Abstand).
- Echte Pfad-Offset-Berechnung an der TODO-Stelle implementieren.
- Zusätzliche Muster in generateHatchLines(for:type:spacing:) ergänzen.
