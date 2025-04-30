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

