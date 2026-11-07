# Azeroth Fitness Tracker

Deutsches Schrittzähler-Addon für WoW: Forever 1.60.1 (Interface 16001), Version 1.3.1.

## Installation

1. WoW schließen.
2. Den Ordner `ForeverSteps` aus diesem Repository nach `Interface/AddOns/` im Forever-Spielordner kopieren.
3. WoW starten und **Azeroth Fitness Tracker** in der Addon-Liste aktivieren.
4. `/aft` öffnet die Einstellungen; `/fitness` zeigt das Hauptfenster.

Der technische Ordnername bleibt `ForeverSteps`, damit bestehende Zähler und Einstellungen erhalten bleiben. Bei einem Update den bisherigen Addon-Ordner ersetzen.

## Funktionen

- Tages- und Gesamtschritte pro Charakter, mit Speicherung über Reload und normales Ausloggen.
- Konfigurierbares Tagesziel und eigene Erfolge für 1, 3, 7, 14, 30 und 100 erfüllte Tagesziele.
- Einklappbare Erfolge; Größenänderung über den Griff unten rechts.
- Rechtsklick sperrt/entsperrt Verschieben und Skalieren.
- Automatisches Ausblenden im Kampf.
- Zahnrad-Menü für Transparenz, Schrift, Rahmenstil und Anzeige der Gesamtschritte.
- Eine lustige Gildennachricht mit `AFT:` beim Erreichen des Tagesziels durch neue Schritte, höchstens einmal täglich. `/fitness gilde` schaltet Nachrichten aus/ein.

## Messung

Die virtuellen Schritte des Charakters werden aus Bewegungsgeschwindigkeit und Zeit geschätzt. Standard: 2,5 Yards pro Schritt. Reiten, Fliegen, Schwimmen, Fahrzeuge, Fallen und Tot-/Geistzustand zählen nicht. Der Tageswechsel richtet sich nach der lokalen Computerzeit. Client-bedingt gesperrte Messwerte werden übersprungen.

Weitere Befehle, Einschränkungen und Änderungshistorie: [Addon-Anleitung](ForeverSteps/README.md).

## Tests

Vom Repository-Verzeichnis aus:

```sh
python3 tests/check.py
```

Benötigt Python 3 und die Systembibliothek Lua 5.4 (`liblua5.4`). Die Tests prüfen die Zähllogik und simulierte WoW-UI-/Event-Aufrufe, einschließlich Tagesziel-Auslösung, Gildenchat, Fenstersperre, Skalierung, Kampfverhalten und Einstellungen. Sie ersetzen keinen Test im echten Forever-Client; die Addon-Dateien verwenden Lua-5.1-kompatible Syntax.
