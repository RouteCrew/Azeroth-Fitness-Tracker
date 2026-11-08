# Azeroth Fitness Tracker

Mehrsprachiges Schrittzähler-Addon für WoW: Forever 1.60.1 (Interface 16001), Version 1.5.0.

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


## Time wasted Running (TWR), ab Version 1.4.0

Das Hauptfenster zeigt die gespeicherte Gesamtlaufzeit pro Charakter als `HH:MM:SS`, ab einem Tag als `Nd HH:MM:SS`. Ein Tooltip erklärt die Anzeige. TWR bleibt auch bei eingeklappten Erfolgen und ausgeblendetem Gesamtschrittzähler sichtbar.

Für jedes gültige Bewegungsintervall gilt: Strecke = aktuelle Geschwindigkeit × Intervallzeit; TWR-Zuwachs = Strecke / aktuelle Geschwindigkeit. Dadurch zählen langsames Gehen und schnelles Laufen jeweils mit ihrer tatsächlichen gemessenen Dauer. Die Schrittlänge beeinflusst TWR nicht.

Es gelten dieselben Ausschlüsse wie beim Schrittzähler: Stillstand, Reiten, Taxi, Fahrzeuge, Fliegen, Schwimmen, Fallen, Tot-/Geistzustand, manuelle Pause, Ladeunterbrechungen und gesperrte Bewegungsdaten werden nicht angerechnet. Ausblenden des Fensters stoppt die Messung nicht. TWR misst geschätzte Laufzeit, keine Zeitersparnis gegenüber Reiten und keine reale Fitnessaktivität.

Bestehende Schritte und Einstellungen bleiben erhalten. TWR beginnt beim Update bei null, da frühere Schrittstände keine verlässlichen Geschwindigkeits- und Zeitdaten enthalten. Der Gesamtzeitstand überlebt Tageswechsel, Reload und normales Ausloggen.


## Mehrsprachigkeit, ab Version 1.5.0

Die Sprache wird automatisch über die WoW-Clientsprache (`GetLocale()`) gewählt. Übersetzt sind Menüs, Einstellungen, Hinweise, Statusmeldungen, Erfolge, TWR-Tooltip, Befehlsausgaben, Addon-Beschreibung und alle vier Gildensprüche. Der Produktname Azeroth Fitness Tracker und der Präfix `AFT:` bleiben unverändert.

Unterstützt: Deutsch, Englisch, Französisch, Spanisch (Spanien und Lateinamerika), Italienisch, Portugiesisch (Brasilien), Russisch, Koreanisch sowie vereinfachtes und traditionelles Chinesisch. enGB verwendet Englisch, ptPT Portugiesisch. Unbekannte Sprachen und fehlende Einträge fallen auf Englisch zurück. Spanische Clientvarianten teilen sich die Übersetzungen.

`/aft` öffnet in jeder Sprache die Einstellungen. Sprachunabhängige Befehle:

- `/fitness show`, `hide`, `lock`, `pause`, `position`, `guild`, `achievements`, `help`
- `/fitness goal 10000`, `/fitness size 1`, `/fitness stride 2.5`

Die bisherigen deutschen Unterbefehle und `/schritte` bleiben gültig. Die Hilfe erklärt die englischen Befehlsschlüssel in der jeweiligen Clientsprache. Nach Änderung der WoW-Sprache das Spiel neu starten; Zähler, TWR und freigeschaltete Erfolge bleiben erhalten.

Für Russisch, Koreanisch und Chinesisch verwendet das Addon ausschließlich die sprachgeeignete WoW-Standardschrift, damit die Zeichen lesbar bleiben. Arial und Morpheus stehen weiterhin in den lateinischen Sprachvarianten zur Auswahl. Längere Texte erhalten eine begrenzte Breite und werden bei Bedarf verkleinert.

Die Texte befinden sich in `ForeverSteps/Locale.lua` und werden vor Zähllogik und Oberfläche geladen. Erweiterte Sprachtests: `python3 tests/check_locales.py` (gleiche Voraussetzungen wie `tests/check.py`). Geprüft werden alle Sprachvarianten, Fallbacks, Schlüsselvollständigkeit, lokalisierte Gildensprüche, Nachrichtenlänge, UI-Aufrufe und bestehende Funktionen. Darstellung und sprachliche Feinheiten wurden nicht in jedem echten Sprachclient geprüft.
