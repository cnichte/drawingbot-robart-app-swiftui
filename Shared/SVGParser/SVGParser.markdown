# SVGParser & CodeGenerator – Dokumentation


Robuste SVG-Verarbeitung mit Ausgabe in verschiedene Steuerformate (z. B. GCode, Eggbot).

---

## SVGParser

### Architekturüberblick

- `SVGParser<T: PlotterCodeGenerator>`:
  - Generischer XML-Parser für SVG-Dateien.
  - Wandelt Elemente wie `<rect>`, `<circle>`, `<path>` usw. in strukturierte `SVGElement`-Objekte um.
  - Skalierung & Transformation (inkl. `translate(...)`) werden automatisch berücksichtigt.
  - Ruft den jeweiligen Generator zur Codeausgabe auf.

- `PlotterCodeGenerator`:
  - Protokoll für Codegeneratoren (z. B. GCode, Eggbot).
  - Implementierungen: `GCodeGenerator`, `EggbotGenerator`.

- `PathParser`:
  - Gemeinsame Utility-Klasse zur Analyse und Approximation von SVG-Pfaden.
  - Unterstützt: M, L, C, Q, A, Z inkl. relativer Varianten.

---

### Unterstützte SVG-Elemente

| Element     | Beschreibung                      | GCodeGenerator            | EggbotGenerator             |
|-------------|-----------------------------------|---------------------------|-----------------------------|
| `<rect>`    | Rechteck                          | 4 G1-Linien               | 4 PD-Linien                 |
| `<circle>`  | Kreis                             | Kreuzförmige 4-Linien     | 24-Punkte Polygon           |
| `<ellipse>` | Ellipse                           | Kreuzförmige 4-Linien     | 24-Punkte Polygon           |
| `<line>`    | Linie zwischen zwei Punkten       | G0 + G1                   | SP + PD                     |
| `<polyline>`| Punktliste, nicht geschlossen     | G0 + G1s                  | SP + PDs                    |
| `<polygon>` | Punktliste, geschlossen           | G0 + G1s + Abschlusslinie | SP + PDs + Abschlusslinie   |
| `<path>`    | Pfade mit M, L, C, Q, A, Z        | Segmentierter Pfad        | Segmentierter Pfad          |

---

### SVG `path`-Kommandos im Detail

SVG-Pfade werden im `d`-Attribut definiert. Die folgenden Kommandos sind derzeit vollständig implementiert:

| Befehl | Bedeutung                     | Parameter                     | Verhalten im Generator                 |
|--------|-------------------------------|-------------------------------|----------------------------------------|
| `M`    | **MoveTo**                    | `x y`                         | Positionieren (Stift oben)             |
| `L`    | **LineTo**                    | `x y`                         | Linie vom aktuellen Punkt              |
| `C`    | **Cubic Bezier Curve**        | `x1 y1 x2 y2 x y`             | Kubische Kurve mit 2 Kontrollpunkten   |
| `Q`    | **Quadratic Bezier Curve**    | `x1 y1 x y`                   | Quadratische Kurve mit 1 Kontrollpunkt |
| `A`    | **Elliptischer Bogen (Arc)**  | `rx ry φ large-arc sweep x y` | Elliptischer Kreisbogen                |
| `Z`    | **Close Path**                | –                             | Zurück zum Startpunkt (Linie)          |

---

#### Die `A`-Parameter:

- `rx`, `ry` – x- und y-Radien des Bogens
- `φ` – Drehwinkel der Ellipse in Grad
- `large-arc` – `0` (kleiner Bogen), `1` (großer Bogen)
- `sweep` – `0` (gegen Uhrzeigersinn), `1` (mit Uhrzeigersinn)
- `x`, `y` – Zielkoordinaten des Bogens

Relativ vs. Absolut:

- Großbuchstaben (M, L, …) → absolute Koordinaten
- Kleinbuchstaben (m, l, …) → relative Koordinaten (von aktuellem Punkt aus)
- Der PathParser behandelt beide Varianten.
    
---

### Skalierung & Transformation

- SVG-Koordinaten werden anhand der Papiergröße skaliert.
- Gruppen-Transformationen wie `translate(x, y)` werden als Transform-Stack umgesetzt.
- Alle Koordinaten werden transformiert über `applyTransform(...)`.

---

### Testbarkeit

- Modular durch `PlotterCodeGenerator`-Protokoll.
- `PathParser` kann isoliert getestet werden.
- Eigene Swift-TestCases für typische `d`-Befehle empfohlen (M, L, C, Q, A, Z).

---

## Befehle in Eggbot- und G-Code-Generatoren

- **Gemeinsamkeiten**: Beide Generatoren unterstützen ähnliche SVG-Elemente (Linien, Rechtecke, Kreise, Ellipsen, Polylinien, Polygone, Pfade) und approximieren komplexe Kurven (z. B. Bezier-Kurven, Bögen) durch lineare Segmente.
- **Unterschiede**: Eggbot verwendet `SP`, `PD`, `PU` für Bewegungen und Zeichnen, während G-Code `G0` und `G1` verwendet. Eggbot schließt Pfade explizit mit `PU`, während G-Code dies nicht immer erfordert.
- **Anwendung**: Beide Generatoren sind für Plotter ausgelegt, aber G-Code ist ein standardisierter Maschinensteuerungscode, während Eggbot-Befehle spezifisch für Eggbot-Plotter sind.

### Eggbot-Befehle

Die `EggbotGenerator.swift` implementiert die folgenden Eggbot-Befehle:

1. **SP,x,y** (Move, Pen Up): Bewegt den Stift (ohne zu zeichnen) zu den angegebenen Koordinaten (x, y). Wird verwendet, um den Stift an eine neue Position zu bringen, bevor das Zeichnen beginnt.
   - Implementiert in der Methode `move(to x: Double, _ y: Double)`.
2. **PD,x,y** (Draw, Pen Down): Zeichnet eine Linie zu den angegebenen Koordinaten (x, y) mit dem Stift unten. Wird verwendet, um Linien zu zeichnen.
   - Implementiert in der Methode `draw(to x: Double, _ y: Double)`.
3. **PU** (Pen Up): Hebt den Stift an, um das Zeichnen zu beenden. Wird typischerweise am Ende eines Pfades oder Elements verwendet.
   - Direkt in den generierten Code-Strings eingefügt, z. B. in `parsePath`, `generateRect`, `generateCircle`, usw.

**Verwendung**: Diese Befehle werden verwendet, um SVG-Elemente wie Linien, Rechtecke, Kreise, Ellipsen, Polylinien, Polygone und Pfade in Eggbot-kompatible Anweisungen zu konvertieren. Komplexe Pfade (z. B. kubische und quadratische Bezier-Kurven, Bögen) werden durch Approximation mit geraden Linien (PD-Befehle) umgesetzt.

| Befehl       | Beschreibung                                                                 | Implementierung                              |
|--------------|------------------------------------------------------------------------------|---------------------------------------------|
| **SP,x,y**   | Bewegt den Stift (ohne zu zeichnen) zu den Koordinaten (x, y) (Pen Up).      | Methode `move(to x: Double, _ y: Double)`   |
| **PD,x,y**   | Zeichnet eine Linie zu den Koordinaten (x, y) (Pen Down).                    | Methode `draw(to x: Double, _ y: Double)`   |
| **PU**       | Hebt den Stift an, um das Zeichnen zu beenden (Pen Up).                      | Direkt in generierten Strings (z. B. `parsePath`, `generateRect`) |

---

### G-Code-Befehle

`GCodeGenerator.swift`-Datei implementiert die folgenden G-Code-Befehle:

1. **G0 Xx Yy**: Schnelle Bewegung (Rapid Move) zu den angegebenen Koordinaten (x, y) ohne Zeichnen (Stift oben). Wird verwendet, um den Stift an eine neue Position zu bewegen.
   - Implementiert in Methoden wie `parsePath`, `generateRect`, `generateCircle`, `generateLine`, `generateEllipse`, `generatePolyline`.
2. **G1 Xx Yy**: Lineare Bewegung (Linear Interpolation) zu den angegebenen Koordinaten (x, y) mit Zeichnen (Stift unten). Wird verwendet, um gerade Linien zu zeichnen.
   - Implementiert in Methoden wie `parsePath`, `generateRect`, `generateCircle`, `generateLine`, `generateEllipse`, `generatePolyline`.

**Verwendung**: Diese Befehle werden verwendet, um SVG-Elemente wie Rechtecke, Kreise, Linien, Ellipsen, Polylinien, Polygone und Pfade in G-Code-kompatible Anweisungen zu konvertieren. Komplexe Pfade (z. B. Bezier-Kurven, Bögen) werden durch lineare Segmente (G1-Befehle) approximiert.


| Befehl       | Beschreibung                                                                 | Implementierung                              |
|--------------|------------------------------------------------------------------------------|---------------------------------------------|
| **G0 Xx Yy** | Schnelle Bewegung zu den Koordinaten (x, y) ohne Zeichnen (Stift oben).      | In `parsePath`, `generateRect`, `generateCircle`, etc. |
| **G1 Xx Yy** | Lineare Bewegung zu den Koordinaten (x, y) mit Zeichnen (Stift unten).       | In `parsePath`, `generateRect`, `generateCircle`, etc. |



## SVG-Hatch-Fill & Pattern-Unterstützung

### Übersicht

Dieses Paket enthält folgende Hauptkomponenten:

- **HatchFillManager.swift**  
  Lädt eine SVG-Datei, wendet verschiedene Hatch-Fill-Algorithmen an, speichert eine „-preview.svg“ und liefert G-Code & EggCode zurück.  
- **SVGPatternSupport.swift**  
  `SVGPatternElementParser` erfasst `<pattern>`-Elemente im SVG, sammelt ihre Kind-Elemente und wandelt pattern-fills automatisch in Hatch-Pfad-Elemente um.  
- **SVGParser+Pattern.swift**  
  Erweiterung des generischen `SVGParser`, um den Pattern-Parser zu integrieren und nach dem Basis-Parsing zusätzliche Hatch-Pfad-Items einzufügen.

### Installation

1. Kopiere **HatchFillManager.swift**, **SVGPatternSupport.swift** und **SVGParser+Pattern.swift** in Dein Xcode-Projekt.  
2. Stelle sicher, dass Du bereits hast:
   - `BasePlotterGenerator.swift`
   - `SVGParser.swift`
   - `GCodeGenerator.swift`
   - `EggbotGenerator.swift`
   - `PathParser.swift`


### 1. Einfacher Hatch-Fill ohne Pattern

```swift
let svgURL = URL(fileURLWithPath: "/Pfad/zu/meinemBild.svg")
let hatch = HatchFillManager()

let (previewURL, gcode, eggcode) = hatch.process(
    inputURL: svgURL,
    hatchType: .lineBased,
    spacing: 8.0,
    svgSize: (width: 300, height: 200),
    paperSize: (width: 300, height: 200)
)

print("Preview: \(previewURL.path)")
print("G-Code Lines: \(gcode.count)")
print("Egg Code Lines: \(eggcode.count)")
```

### 2. Hatch-Fill mit Pattern-Erkennung

```swift
// 1. SVG-Parser mit Pattern-Parser initialisieren
let hatch = HatchFillManager()
let patternParser = SVGPatternElementParser(
    hatchManager: hatch,
    defaultType: .patternBased,
    defaultSpacing: 6.0
)

let parser = SVGParser(generator: BasePlotterGenerator())
// Weisen Sie dem Parser Ihre patternParser-Instanz zu:
parser.patternParser = patternParser

// 2. SVG mit Pattern parsen
let loaded = parser.loadSVGFile(
    from: svgURL,
    svgWidth: 300, svgHeight: 200,
    paperWidth: 300, paperHeight: 200
)

guard loaded else { fatalError("Parsing fehlgeschlagen") }

// 3. Ergebnisse aus parser.elements entnehmen
for item in parser.elements {
    print(item.output)
}
```

### Verfügbare Hatch-Algorithmen

- Line-Based: Parallele Linien im Bounding-Box.
- Grid-Based: Zusätzlich vertikal + horizontal.
- Pattern-Based: Kreuzlinien + Diagonalen.
- Contour-Following: Verschachtelte Rechtecke (aktuell implementiert nur für Rechtecke).
- Stippling: Zufällige Punkt-Paare (als kleine Linien).


### Fehlende Features & TODOs

1. Contour-Following für beliebige Pfade
    - Derzeit nur als Rechteck-Inset implementiert.
    - TODO: Pfad-Offset-Bibliothek oder eigene Kontur-Offset-Berechnung für beliebige SVGElement-Konturen.

1. Erweiterte `<pattern>`-Attribute
    - patternUnits (userSpaceOnUse vs. objectBoundingBox).
    - patternTransform, viewBox, width/height im Pattern.
    - Unterstützung für gekachelte Pattern-Instanzen über den gesamten Shape.

1. Verschachtelte Pattern & Referenzen
    - `<pattern>` kann andere `<pattern>` referenzieren.
    -  TODO: Rekursive Auflösung verschachtelter Patterns.

1. Nicht-Rechteckige Shapes
    - Alle Hatch-Algorithmen basieren aktuell auf Bounding-Box.
    - TODO: Clipping der Linien an der wahren Kontur (Pfad-Schnitt).

1. Performance & Speicher
    - Für sehr große SVGs viele temporäre Strings.
    - TODO: Streaming-Parsing / Codegenerierung ohne vollständiges Zwischenspeichern aller Items.

1. Unit-Tests und Beispiele
    - Es fehlen automatisierte Tests für alle Algorithmen.
    - TODO: XCTest-Suite mit Beispiel-SVGs und erwarteten Outputs.
