# Azeroth Fitness Tracker 1.4.0

Deutsches Schrittzähler-Addon für WoW: Forever 1.60.1 (Interface 16001).

## Installation
1. WoW vollständig schließen.
2. Den Ordner `ForeverSteps` aus dem ZIP nach `Interface/AddOns/` im verwendeten Forever-Spielordner kopieren. In der Beta ist das üblicherweise `_classic_beta_/Interface/AddOns/`.
3. Prüfen: `Interface/AddOns/ForeverSteps/ForeverSteps.toc` muss direkt vorhanden sein, ohne zusätzlichen Zwischenordner.
4. WoW starten und Azeroth Fitness Tracker in der Addon-Liste aktivieren.
5. Im Spiel `/schritte` eingeben.

## Anzeige und Speicherung
- Verschiebbares Fenster mit WoW-Texturen, goldenem Rahmen, Tageszahl, Gesamtzahl und Tageszielbalken.
- Linke Maustaste halten, um das Fenster zu verschieben.
- Tageswechsel um Mitternacht nach lokaler Computerzeit, nicht zum täglichen Quest-Reset.
- Gesamtstand und Einstellungen bleiben bei normalem Ausloggen und `/reload` erhalten; bei einem Spielabsturz können die seit dem letzten Speichern gezählten Schritte verloren gehen.
- Alle Werte gelten pro Charakter. Verstecken des Fensters stoppt die Zählung nicht.
- Keine rückwirkende Erfassung vor der Installation. Keine externen Bibliotheken erforderlich.

## Befehle
| Befehl | Funktion |
| --- | --- |
| `/schritte` | Fenster anzeigen |
| `/schritte ausblenden` | Fenster verstecken, weiterzählen |
| `/schritte sperren` | Verschieben sperren / entsperren |
| `/schritte pause` | Zählen pausieren / fortsetzen |
| `/schritte ziel 10000` | Tagesziel setzen (1–1.000.000) |
| `/schritte groesse 1,2` | Fensterskalierung (0,6–2) |
| `/schritte schrittlaenge 2,5` | Yards pro geschätztem Schritt (0,5–5), nur für neue Schritte |
| `/schritte position` | Fenster mittig platzieren |
| `/schritte hilfe` | Befehle anzeigen |

`/fsteps` ist ein Alias für `/schritte`.

## Was wird gezählt?
Gemeint sind virtuelle Schritte deines Charakters, keine realen Schritte mit Handy oder Fitnessuhr. Das Addon schätzt sie aus Bewegungsgeschwindigkeit × Zeit / Schrittlänge. Standard: 2,5 Yards je Schritt. Das ist eine konfigurierbare Spielkonvention, keine Messung der Fußanimation. Gehen, Rennen und Bewegungsgestalten zu Fuß werden erfasst. Reiten, Taxi, Fahrzeuge, Fliegen, Schwimmen, Fallen/Springen und Tot-/Geistzustand werden ausgeschlossen.

Die Messung verwendet GetUnitSpeed, keine Kartenkoordinaten. Sie kann deshalb etwa beim Laufen gegen Hindernisse von der tatsächlich zurückgelegten Strecke abweichen. Ladebildschirme und einzelne Frames über 0,5 Sekunden werden nicht angerechnet. Unter Client-API-Beschränkungen werden Werte sicher übersprungen und der Status informiert über die fehlende Messung. Es wird nichts nachträglich geschätzt.

## Kompatibilität und Prüfung
Ziel ist Forever 1.60.1 / Interface 16001. Bei anderen Builds im Spiel `/run print(select(4, GetBuildInfo()))` ausführen und die Interface-Nummer in der TOC prüfen. Eine angepasste Nummer allein garantiert keine API-Kompatibilität.

Die Zähllogik wurde außerhalb von WoW auf Tageswechsel, Teil-Schritte, Pausen und Ladeunterbrechungen geprüft. Ein echter Ingame-Test war hier nicht möglich. Nach der Installation kurz laufen, stehen bleiben, reiten und `/reload` ausführen; Stand und Fensterposition sollten erhalten bleiben.

Technische Referenzen:
- https://github.com/tobarisu1/wow_forever_addons (Forever-Client und Interface-Version)
- https://github.com/Thunderz96/forever-addon-kit (Forever-API-Besonderheiten)
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua (GetUnitSpeed und geschützte Werte)


## Neu in 1.1.0
- Anzeigename: WoW Fitness. Der technische Ordnername ForeverSteps bleibt absichtlich erhalten, damit bestehende Charakterdaten weitergeladen werden. Bei geschlossenem Spiel den bisherigen Ordner durch diesen ersetzen. Nicht beide Versionen gleichzeitig installieren.
- Ziehgriff unten rechts im Fenster (60–200 %), alternativ `/fitness groesse 1,2`.
- `/fitness` als weiterer Hauptbefehl.
- Einmal pro erreichtem Tagesziel eine zufällige lustige Gildennachricht. `/fitness gilde` schaltet sie aus/ein. Ohne Gilde erfolgt nur die lokale Gratulation. Keine nachträglichen Gildennachrichten, keine Wiederholungen nach Reload oder Zieländerungen am selben Tag. Bei Chat-Blockierung erfolgt kein automatischer erneuter Sendeversuch. Ein Absturz vor der Speicherung kann wie bei den Schritten auch diese Tagesmarkierung verlieren.
- Eigene Addon-Erfolge für 1, 3, 7, 14, 30 und 100 erfüllte Tagesziele: Der erste Schweiß; Sohlen statt Portale; Eine Woche Waden; Mount hat Urlaub; Azeroths Lauflegende; Die Sohlen des Schicksals.
- Die Tage müssen nicht aufeinanderfolgen. Jeder Kalendertag zählt höchstens einmal. Erfolge werden im Fenster und per `/fitness erfolge` angezeigt und pro Charakter gespeichert. Es sind keine offiziellen Blizzard-Erfolge und es gibt keine Blizzard-Erfolgspunkte.
- Nur das Überschreiten der Zielschwelle durch neue gezählte Schritte löst die Gratulation, Tagesziel-Wertung und Gildennachricht aus. Login, Reload und Herabsetzen des Ziels lösen nichts aus. Ein bereits erfülltes Ziel wird nicht nachträglich gemeldet. Frühere Tage lassen sich aus der alten Version nicht rekonstruieren.
- Neue Funktionen mit Lua-Testfällen und simulierten WoW-Aufrufen geprüft, noch nicht im echten Forever-Client getestet.


## Neu in 1.2.0: Fensterbedienung
- Den Griff unten rechts mit der linken Maustaste ziehen: Das gesamte Fenster inklusive Schrift skaliert proportional von 60 bis 200 Prozent. Die obere linke Ecke bleibt stehen.
- Rechtsklick auf den Fensterhintergrund oder Ziehgriff sperrt/entsperrt das Fenster. Gesperrt sind Verschieben, Ziehen am Größen-Griff und die Befehle für Größe/Position blockiert. Die Sperre bleibt nach Reload erhalten.
- Beim Kampfbeginn wird das Fenster ausgeblendet, nach Kampfende wieder eingeblendet. Manuell ausgeblendete Fenster bleiben verborgen. Auch `/fitness` zeigt das Fenster während des Kampfes nicht an.
- Ein aktives Ziehen wird beim Sperren oder Ausblenden beendet. Schritte werden bei verborgenem Fenster weiterhin gezählt, soweit die Bewegungs-API sie liefert.
- Der bisherige Größenregler wurde entfernt. `/fitness groesse 1,2` funktioniert weiterhin bei entsperrtem Fenster außerhalb des Kampfes.


## Neu in 1.3.0: Kompakte Erfolge und Dialogeinstellungen
- Erfolge starten eingeklappt. Mit +/− neben ERFOLGE die Liste aus-/einklappen. Das Fenster wird entsprechend kleiner/größer, die obere linke Ecke bleibt stehen. Der Zustand wird pro Charakter gespeichert.
- Das Zahnrad oben rechts links neben X öffnet die Einstellungen.
- Transparenz: 0–75 % für das gesamte Hauptfenster. Das Einstellungsfenster bleibt lesbar und deckend.
- Schrift: WoW Standard, Arial oder Morpheus. Rahmen: Gold, Schlicht oder Ohne Rahmen. Auf die jeweilige Schaltfläche klicken, um zur nächsten Variante zu wechseln.
- Gesamtschritte An/Aus blendet den Gesamtzähler samt Überschrift ein/aus. Auch bei ausgeblendeter Anzeige werden die Schritte weitergezählt. Standardmäßig ist er sichtbar.
- Alle Einstellungen werden sofort im Charakterzustand übernommen und beim normalen Ausloggen oder Reload gespeichert.
- Die Fenstersperre blockiert weiterhin Verschieben und Ziehskalierung; Einstellungen und Einklappen bleiben bedienbar. Der Eckgriff berücksichtigt beide Fensterhöhen. Im Kampf werden Hauptfenster und Einstellungen verborgen; nach Kampfende bleibt das Einstellungsfenster geschlossen.
- In simulierten Lua-Tests geprüft. Darstellung und Interaktion im echten Forever-Client bitte nach dem Update prüfen.


## Neu in 1.3.1
- Ingame-Name: Azeroth Fitness Tracker.
- `/aft` öffnet direkt dasselbe Einstellungsmenü wie das Zahnrad. Ein verborgenes Hauptfenster wird dabei eingeblendet. Im Kampf bleiben Fenster und Einstellungen verborgen.
- Gildennachrichten beginnen mit `AFT: `. Sie werden weiterhin nur beim Erreichen des Tagesziels durch neue Schritte ausgelöst, maximal einmal pro Tag.
- Die bisherigen Befehle bleiben verfügbar. Der technische Ordner und die gespeicherten Charakterdaten heißen weiterhin ForeverSteps, damit vorhandene Zähler und Einstellungen erhalten bleiben.


## Time wasted Running (TWR), ab Version 1.4.0

Das Hauptfenster zeigt die gespeicherte Gesamtlaufzeit pro Charakter als `HH:MM:SS`, ab einem Tag als `Nd HH:MM:SS`. Ein Tooltip erklärt die Anzeige. TWR bleibt auch bei eingeklappten Erfolgen und ausgeblendetem Gesamtschrittzähler sichtbar.

Für jedes gültige Bewegungsintervall gilt: Strecke = aktuelle Geschwindigkeit × Intervallzeit; TWR-Zuwachs = Strecke / aktuelle Geschwindigkeit. Dadurch zählen langsames Gehen und schnelles Laufen jeweils mit ihrer tatsächlichen gemessenen Dauer. Die Schrittlänge beeinflusst TWR nicht.

Es gelten dieselben Ausschlüsse wie beim Schrittzähler: Stillstand, Reiten, Taxi, Fahrzeuge, Fliegen, Schwimmen, Fallen, Tot-/Geistzustand, manuelle Pause, Ladeunterbrechungen und gesperrte Bewegungsdaten werden nicht angerechnet. Ausblenden des Fensters stoppt die Messung nicht. TWR misst geschätzte Laufzeit, keine Zeitersparnis gegenüber Reiten und keine reale Fitnessaktivität.

Bestehende Schritte und Einstellungen bleiben erhalten. TWR beginnt beim Update bei null, da frühere Schrittstände keine verlässlichen Geschwindigkeits- und Zeitdaten enthalten. Der Gesamtzeitstand überlebt Tageswechsel, Reload und normales Ausloggen.
