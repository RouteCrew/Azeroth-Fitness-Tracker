# Azeroth Fitness Tracker 1.6.0 – Einstellungen

`/aft` oder das Zahnrad öffnet ein eigenes, verschiebbares Menü mit vier Seiten. Es passt seine Größe an kleinere Bildschirme an und wird im Kampf geschlossen. Alle Texte folgen weiterhin der WoW-Clientsprache. Eigene Texte werden nicht automatisch übersetzt.

## Allgemein

Hier lassen sich Tagesziel, Schrittlänge, Fenstergröße, Transparenz, Schrift und Rahmen konfigurieren. Schalter steuern Gesamtschritte, TWR, Kalorienanzeige, Gildennachrichten, Messpause, Fenstersperre und eingeklappte Erfolge. Zahlenfelder mit **Speichern** übernehmen; Schalter wirken sofort. Bei gesperrtem Fenster sind Größe und Position geschützt.

## Ziele und Farben

Bis zu 20 eigene tägliche Schrittziele mit Namen und Schrittzahl anlegen, bearbeiten oder löschen. Mit den Pfeilen ein bestehendes Ziel auswählen, mit **Neu** ein weiteres anlegen. Das ausgewählte Ziel zeigt den aktuellen Tagesfortschritt.

Jedes Ziel wird nur beim Überschreiten seiner Schwelle durch neue Schritte einmal pro Kalendertag lokal gemeldet. Bloßes Senken eines Ziels löst keine Meldung aus. Neue Ziele oberhalb des bisherigen Tagesstands können noch am selben Tag erreicht werden. Bearbeiten eines bereits erledigten Ziels vergibt es nicht erneut. Tageswechsel setzt die eigenen Tageserfolge zurück.

Die bisherigen Langzeiterfolge und die tägliche Gildennachricht beziehen sich weiterhin auf das Haupt-Tagesziel. Zusätzliche eigene Ziele erzeugen keinen Gildenchat-Spam.

Die Farben beziehen sich auf erreichte absolute Tages-Schrittstände:

| Erreicht | Farbe | HEX |
| --- | --- | --- |
| Unter 10.000 | Goldbraun | d9a33d |
| 10.000 | Orange | ff9900 |
| 20.000 | Blau | 3388ff |
| 30.000 | Grün | 33cc66 |
| 40.000 | Violett | aa66ee |
| 50.000 | Rot | ff4444 |
| 60.000 | Gold | ffcc33 |
| 70.000 | Türkis | 33dddd |
| 80.000 | Rosa | ff77bb |
| 90.000 | Silber | cccccc |
| 100.000 | Goldgelb | ffd700 |

Die Füllung zeigt `heutige Schritte / nächster Meilenstein`; beim Erreichen einer Stufe wird auf den nächsten Meilenstein umgestellt. Die Farbe bleibt dabei sichtbar, beispielsweise Orange bei 10.000 von nun 20.000 Schritten. Nach der letzten Stufe bleibt die Leiste voll. Das Haupt-Tagesziel wird separat als Zahl und Prozent angezeigt.

Eigene Farbstufen: pro Zeile `Schrittzahl #HEX`, z. B. `15000 #ff9900`. Bis zu 20 eindeutige Stufen von 1 bis 10.000.000; sie werden beim Speichern sortiert. **Standard wiederherstellen** stellt die Tabelle oben wieder her. Farbstufen sind unabhängig von eigenen benannten Zielen.

## Gildensprüche

Die vier eingebauten Sprüche können geändert werden; bis zu 30 Sprüche je Clientsprache sind möglich. Ein Spruch bleibt mindestens erhalten. Die Pfeile wählen einen Spruch aus. **Neu**, **Speichern** und **Löschen** bearbeiten den Vorrat; **Standard wiederherstellen** setzt nur den Text im aktuellen Editor auf einen der Standardsprüche zurück und muss anschließend gespeichert werden.

| Platzhalter | Inhalt |
| --- | --- |
| `{steps}` | Heutige Schritte |
| `{total_steps}` | Gesamtschritte seit Installation |
| `{time}` | Heutige gemessene Laufzeit |
| `{total_time}` | Gesamte gemessene Laufzeit (TWR) |
| `{goal}` | Haupt-Tagesziel |

Beispiel: `Schon {steps} Schritte in {time}! Meine Stiefel kündigen.`

**Vorschau** ersetzt die Platzhalter mit echten Zählerständen, sendet aber nichts. `AFT: ` wird automatisch vorangestellt. Im Spiel wird beim Erreichen des Haupt-Tagesziels ein zufälliger gespeicherter Spruch gesendet, höchstens einmal täglich. Gildennachrichten lassen sich abschalten.

Unbekannte Platzhalter, Links/Steuercodes und Zeilenumbrüche werden abgelehnt. Vorlagen dürfen höchstens 500 Bytes lang sein. Ausgehende Nachrichten werden bei Bedarf UTF-8-sicher auf 255 Bytes gekürzt. Nicht gespeicherte Editoränderungen gehen beim Wechseln der Seite verloren.

## Fantasie-Kalorien

Dies sind Spielwerte für den Charakter. WoW selbst hat kein entsprechendes Ernährungssystem.

`Tagesbedarf = Rassen-Grundbedarf + gemessene Strecke in Yards × Bewegungsfaktor`

`Noch offen = max(0, Tagesbedarf − gegessene Kalorien)`

Die Leiste zeigt den noch offenen Anteil; Essen senkt sie, Bewegung kann sie wieder erhöhen. Überzählige Kalorien bleiben für den restlichen Tag als gegessen verbucht. An Mitternacht nach Computerzeit werden Aufnahme und bewegungsbedingter Bedarf zurückgesetzt. Basiswerte und Einstellungen bleiben erhalten.

Fantasie-Startwerte für bekannte Rassen:

| Rassentoken | kcal/Tag |
| --- | --- |
| Human | 2.200 |
| Orc | 3.000 |
| Dwarf | 2.600 |
| NightElf | 2.100 |
| Scourge | 1.200 |
| Tauren | 4.200 |
| Gnome | 1.400 |
| Troll | 2.800 |
| Skyborne / SkyborneAlliance | 2.300 |
| SkyborneHorde | 2.400 |

Die Rasse wird aus `UnitRace("player")` gelesen. Weitere bekannte WoW-Rassentokens sind ebenfalls hinterlegt. Noch unbekannte Tokens bekommen einen stabilen Fantasiewert zwischen 2.000 und 2.999. Das Menü zeigt den tatsächlich erkannten Token und erlaubt, den Grundbedarf für diese Rasse pro Charakter zu ändern.

Standard-Bewegungsfaktor: 0,02 kcal je gemessenem Yard. Er ist unabhängig von der eingestellten Schrittlänge. Stillstand und ausgeschlossene Bewegungsarten werden wie bei TWR nicht angerechnet. Die Messpause pausiert die Bewegungsdaten; sie schaltet die separate Essenserkennung nicht aus.

Standardmahlzeit: 250 kcal. Die automatische Erkennung verwendet erfolgreich gewirkte Essenszauber des Spielers, mit Schutz vor doppelten Cast-Ereignissen. Die Basis-IDs 433, 434 und 435 sowie Zauber mit demselben lokalisierten Namen wie 433 werden erkannt. Reine Trinkzauber, Tränke und fremde Einheiten zählen nicht. Ein verbrauchtes Essen wird einmal gezählt, nicht für jeden Regenerationstick; Abbruch des Sitzens macht den bereits verbrauchten Gegenstand nicht rückgängig.

Besondere Nahrungsmittel, anders benannte Essen-Zauber oder clientseitig gesperrte Ereignisse können ohne Buchung bleiben. Für diese Fälle gibt es:

- Zuordnungen `Zauber-ID kcal` pro Zeile, z. B. `12345 400`. Die Zahl ist eine **Zauber-ID**, keine Item-ID. `433 0` schließt diesen Zauber ausdrücklich aus.
- Eine Anzeige der letzten sichtbaren Spieler-Zauber-ID auf der Kalorienseite.
- **Mahlzeit manuell buchen** für eine Standardmahlzeit.
- **Letzte Mahlzeit zurück** für die letzte automatische oder manuelle Buchung; einmalig und nur am selben Tag.
- Einen Schalter für automatische Erkennung.

Die tatsächlichen Essensereignisse und neuen Bedienelemente wurden noch nicht im Forever-Client geprüft. Die Tests simulieren erfolgreiche, doppelte, fremde, gesperrte und ausgeschlossene Essensereignisse.

## Update und Speicherung

Den vorhandenen Ordner `ForeverSteps` bei geschlossenem Spiel ersetzen. Schritte, TWR, Erfolge und bisherige Einstellungen bleiben erhalten. Die neue heutige Laufzeit und die Kaloriendaten beginnen beim Update bei null; historische Tageswerte können nicht rekonstruiert werden.

SavedVariables werden beim normalen Ausloggen oder `/reload` auf die Festplatte geschrieben. Bei einem Absturz kann der Fortschritt seit dem letzten Speichern verloren gehen.
