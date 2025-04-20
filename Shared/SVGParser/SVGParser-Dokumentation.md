# SVGParser & CodeGenerator – Dokumentation


Robuste SVG-Verarbeitung mit Ausgabe in verschiedene Steuerformate (z. B. GCode, Eggbot).

---

## Architekturüberblick

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

## Unterstützte SVG-Elemente

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

## SVG `path`-Kommandos im Detail

SVG-Pfade werden im `d`-Attribut definiert. Die folgenden Kommandos sind derzeit vollständig implementiert:

| Befehl | Bedeutung                     | Parameter                     | Verhalten im Generator     |
|--------|-------------------------------|-------------------------------|-----------------------------|
| `M`    | **MoveTo**                    | `x y`                         | Positionieren (Stift oben) |
| `L`    | **LineTo**                    | `x y`                         | Linie vom aktuellen Punkt |
| `C`    | **Cubic Bezier Curve**        | `x1 y1 x2 y2 x y`             | Kubische Kurve mit 2 Kontrollpunkten |
| `Q`    | **Quadratic Bezier Curve**    | `x1 y1 x y`                   | Quadratische Kurve mit 1 Kontrollpunkt |
| `A`    | **Elliptischer Bogen (Arc)**  | `rx ry φ large-arc sweep x y` | Elliptischer Kreisbogen |
| `Z`    | **Close Path**                | –                             | Zurück zum Startpunkt (Linie) |

### Die `A`-Parameter:

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

## Skalierung & Transformation

- SVG-Koordinaten werden anhand der Papiergröße skaliert.
- Gruppen-Transformationen wie `translate(x, y)` werden als Transform-Stack umgesetzt.
- Alle Koordinaten werden transformiert über `applyTransform(...)`.

---

## Testbarkeit

- Modular durch `PlotterCodeGenerator`-Protokoll.
- `PathParser` kann isoliert getestet werden.
- Eigene Swift-TestCases für typische `d`-Befehle empfohlen (M, L, C, Q, A, Z).

