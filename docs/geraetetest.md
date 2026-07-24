# Gerätetest-Checkliste

Alles aus v6.1–v7.3 wurde gebaut, aber noch nie auf einem echten Gerät benutzt. Diese Liste ist für genau diese eine große Session gedacht: einmal von oben nach unten, mit einem Handy **und** einem Tablet.

Warum überhaupt eine Liste: Die Test-Suite deckt Logik und Beschriftungen ab, aber nichts von dem, was hier steht — Gesten, Druckstärke, Systemdialoge, Layout auf echten Seitenverhältnissen, Musik, Vibration.

**Vorbereitung**

```bash
flutter analyze && flutter test          # muss beides sauber sein
flutter run --release -d <geräte-id>     # Release, nicht Debug — Debug ist spürbar langsamer
```

**Erster Schritt auf dem Gerät: der Rauchtest** (seit v7.9). Er fährt den mechanischen Anfang dieser Liste automatisch ab — App starten, Bild öffnen, malen, verlassen, Bild liegt auf der Platte — und prüft nebenbei, dass die App dabei nichts in ihr Fehlerlog geschrieben hat:

```bash
flutter test integration_test/app_test.dart -d <geräte-id>
```

Läuft er durch, ist die Grundmechanik auf diesem Gerät bewiesen und du kannst dich auf das konzentrieren, was nur ein Mensch beurteilen kann: Gesten, Druckstärke, Layout, Töne, Tempo. Scheitert er, steht im Fehlertext, an welchem Schritt — das ist dann der erste Befund der Session.

> Der Test legt genau ein Bild an und löscht es am Ende wieder. Auf einem Gerät mit echten Kinderbildern rührt er sonst nichts an.

Auf einem Gerät testen, auf dem die App **noch nicht** installiert war (oder vorher `adb uninstall dev.rb.pixiepaint`), damit auch der erste Start mitgeprüft wird. Achtung: damit sind vorhandene Bilder weg.

---

## Erster Start

- [ ] Splash erscheint, App startet ohne Ruckler
- [ ] **Begrüßung** erscheint (nur beim allerersten Start): drei Karten zum Durchwischen
- [ ] „Überspringen" ist schon auf der ersten Karte da und führt direkt in die Bildauswahl
- [ ] „Los malen!" auf der letzten Karte führt ebenfalls in die Bildauswahl
- [ ] App neu starten → die Begrüßung kommt **nicht** wieder
- [ ] Startseite zeigt alle Kacheln; auf dem Handy fehlt „Zu zweit malen" (nur ab 600 dp)
- [ ] Tagesaufgaben-Banner ist da und nennt eine Aufgabe
- [ ] Es läuft keine Musik (Standard ist aus)

## Malen — Grundlagen

- [ ] Ausmalbild öffnen: Linien scharf, Flächen füllen sich sauber und laufen nicht aus
- [ ] Alle 9 Stifte durchprobieren — jeder sieht deutlich anders aus
- [ ] Alle 8 Füllmuster durchprobieren
- [ ] Formen aufziehen: Live-Vorschau folgt dem Finger, Loslassen setzt die Form
- [ ] Pinselgröße über den Schieber von ganz klein bis ganz groß
- [ ] Radierer, Undo, Redo — auch mehrfach hintereinander
- [ ] Pipette nimmt die Farbe unter dem Finger auf
- [ ] Zwei-Finger-Zoom und Verschieben; „Ansicht zurücksetzen" stellt wieder her
- [ ] **Werkzeugwechsel mehrfach hin und her** — in v6.7 wurde hier ein Absturzpfad behoben (negativer Schatten-Blur), das ist die Gegenprobe
- [ ] Zauber-Spiegel in allen drei Stufen

**Erreichbarkeit der Leiste** (neu in v8.0 — das Handy im Hochformat ist hier der Prüfstein)

- [ ] Rückgängig und Wiederholen sind **ohne zu wischen** sichtbar, direkt nach dem Öffnen eines Bildes
- [ ] Die Werkzeuge daneben lassen sich wischen; die weiche Kante zeigt, dass es weitergeht
- [ ] Sticker oder Form über das Auswahl-Blatt wählen → das gewählte Werkzeug rutscht von selbst in den sichtbaren Bereich
- [ ] Linkshänder-Modus an: Rückgängig/Wiederholen wechseln die Seite
- [ ] „Alles weg" (Besen) sitzt am Ende der Werkzeuge und fragt weiterhin nach
- [ ] Beim allerersten Bild auf einem **Handy** erscheint einmalig der Hinweis „Quer hast du mehr Platz" — antippen lässt ihn verschwinden, nach ein paar Sekunden geht er von selbst
- [ ] Nächstes Bild öffnen: der Hinweis kommt **nicht** wieder; auf dem Tablet erscheint er gar nicht

**Einfache Werkzeuge** (neu in v8.1)

- [ ] Einstellungen des Kinderprofils (Profil-Chip → Verwalten → Stift-Symbol): der Schalter „Einfache Werkzeuge" ist da; das Blatt lässt sich scrollen, auch wenn die Tastatur offen ist
- [ ] Mit Schalter an: nur Pinsel, Füllen, Sticker, Radierer — sichtbar größer; kein Zauber-Spiegel, Pinselgröße bleibt
- [ ] Der Farbeimer malt sofort (kein Muster-Blatt dazwischen)
- [ ] Rückgängig ist weiterhin da
- [ ] Zweites Kind ohne den Schalter anlegen und wechseln → dort sind wieder alle 14 Werkzeuge da

## Stift und Handballen (nur mit Stylus)

- [ ] Druckstärke ändert die Strichbreite
- [ ] Mit „nur mit Stift malen" an: Finger malt nicht mehr, Stift schon
- [ ] Handballen auf dem Display hinterlässt keine Striche

## Speichern und Galerie

- [ ] Bild malen, App über den Home-Button in den Hintergrund schicken, zurückkehren → Bild ist noch da
- [ ] Bild verlassen, Galerie öffnen → Bild ist gespeichert, Vorschaubild stimmt
- [ ] Umbenennen, favorisieren, Filter „Favoriten"
- [ ] Weitermalen an einem gespeicherten Bild
- [ ] Löschen (mit und ohne die Einstellung „Löschen nur für Eltern")
- [ ] Diashow läuft und der Bildschirm schaltet sich dabei nicht ab
- [ ] **Diashow sofort wieder verlassen**, bevor das erste Bild da ist — in v7.4 wurde hier ein Absturzpfad behoben, das ist die Gegenprobe

## Neue Inhalte (v7.6)

- [ ] Kategorie **Bauernhof** ist im Picker da und hat fünf Bilder; jedes einmal antippen und eine Fläche füllen
- [ ] Die anderen fünf neuen Bilder (Pinguin, Kaktus, Fee, Lolli, Sternschnuppe) ebenfalls einmal füllen — **läuft nirgends Farbe aus**, das ist der eine Fehler, den nur das Gerät zeigt
- [ ] Vier neue Zahlenbilder (Rakete, Regenschirm, Kuchen, Haus): Palette zeigt die Nummern, richtige Farbe füllt
- [ ] Zwei neue Szenen (Dschungel, Zirkus) bekleben und speichern
- [ ] **Systemsprache auf Türkisch (oder Polnisch) stellen** und in die Bildauswahl gehen: die Motivnamen und die Kategorie-Tabs sind übersetzt, nicht deutsch. Danach zurückstellen.
- [ ] Musik einschalten und **dreimal aus- und wieder einschalten**: es kommen drei verschiedene Stücke, das neue („Spieluhr") läuft ohne Knacken über den Schleifenpunkt
- [ ] Tagesaufgaben-Banner nennt eine Aufgabe; über mehrere Tage (oder mit gestellter Gerätezeit) kommen unterschiedliche

## Die anderen Spielarten

- [ ] **Malen nach Zahlen:** Palette zeigt die Nummern, richtige Farbe füllt, falsche nicht; fertiges Bild feiert
- [ ] **Nachspuren:** Buchstabe, Zahl und Form je einmal; Erkennung springt an, wenn genug nachgefahren wurde
- [ ] **Sticker-Welt:** Szene wählen, Sticker platzieren, weitermalen, speichern
- [ ] **Zeitraffer:** Bild aus der Galerie als Film abspielen, Geschwindigkeit ändern
- [ ] **Zu zweit malen** (Tablet): beide Seiten gleichzeitig bemalen, eine Seite drehen, speichern → ein zusammengesetztes Bild in der Galerie
  - [ ] Neu in v7.2: einige Minuten malen, dann den Home-Button drücken und zurückkehren → das Bild ist in der Galerie, und zwar **genau einmal**, nicht mehrfach
- [ ] **Foto anmalen:** Foto auswählen und bemalen
- [ ] **Foto → Ausmalbild:** alle drei Detailstufen ansehen

## Belohnungen und Tagesaufgabe

- [ ] Genug Bilder fertigstellen, bis ein Sticker freigeschaltet wird → Feier erscheint beim Verlassen des Bildes
- [ ] Gesperrte Sticker wackeln als Mystery-Box und zeigen den Fortschritt
- [ ] Sticker-Auswahl öffnen, **wenn alle Sticker freigespielt sind** — auch dann kein Absturz (v7.4)
- [ ] Tagesaufgabe erledigen → sie zählt genau einmal, auch bei mehrfachem Antippen

## Profile

- [ ] Zweites Kind anlegen, Namen und Gesicht setzen
- [ ] Umschalten: Galerie zeigt nur die Bilder des aktiven Kindes
- [ ] Belohnungs-Fortschritt ist je Kind getrennt
- [ ] Kind entfernen — einmal mit „Bilder behalten", einmal mit „Bilder auch löschen"

## Eltern-Bereich

- [ ] Elternschranke: falsche Antwort blockt, dreimal falsch bricht ab, richtige lässt durch
- [ ] Alle Schalter umlegen und die App neu starten → alle Einstellungen sind noch gesetzt
- [ ] Linkshänder-Modus: Werkzeuge wandern auf die andere Seite
- [ ] Töne und Vibration an/aus hörbar bzw. spürbar
- [ ] Musik an: beide Stücke anspielen; Musik pausiert, wenn die App in den Hintergrund geht
- [ ] **Sicherung erstellen** → ZIP landet im Share-Sheet, Datei ist nicht leer
- [ ] **Sicherung zurückholen** (die wichtigste neue Funktion aus v6.7):
  - [ ] auf einem Gerät ohne Bilder → alle Bilder und Profile sind wieder da
  - [ ] auf einem Gerät mit Bildern → vorhandene Bilder bleiben unverändert, die Meldung nennt die Zahlen
  - [ ] eine beliebige andere ZIP-Datei auswählen → freundliche Ablehnung, kein Absturz
- [ ] **Speicherplatz:** Anzeige plausibel; ein paar Bilder auswählen und löschen; Anzeige schrumpft
- [ ] **Problembericht** (neu in v7.5): Einstellungen → „Problembericht". Erwartung nach einem sauberen Durchlauf: „Alles in Ordnung". Steht dort etwas, ist das ein Befund — Eintrag antippen (zeigt den Stack), dann „Bericht teilen" und die Datei aufbewahren. Ein Eintrag mit `save` heißt: etwas wurde nicht gespeichert, und das ist der wichtigste Fund, den diese Session machen kann.

## Teilen, Drucken, Fotos

- [ ] Teilen öffnet das System-Share-Sheet, das Bild kommt vollständig an
- [ ] „In Fotos speichern" landet in der Galerie des Geräts
- [ ] Drucken zeigt die PDF-Vorschau richtig
- [ ] Beim ersten Mal erscheinen die Berechtigungsdialoge mit den deutschen Texten aus der Info.plist bzw. dem Manifest

## Barrierefreiheit (neu in v6.7)

- [ ] **TalkBack (Android) bzw. VoiceOver (iOS) einschalten** und über die Startseite wischen — jede Kachel wird benannt
- [ ] Werkzeugleiste durchwischen: jedes Werkzeug wird benannt, das aktive zusätzlich als „ausgewählt"
- [ ] Farbpalette durchwischen: die Farben heißen „Rot", „Blau" usw., nicht 16-mal dasselbe
- [ ] Der Malbereich wird als eine Fläche angesagt, nicht Pixel für Pixel
- [ ] **Systemschrift auf das Maximum stellen** und durch alle Screens gehen: nichts überlappt, nichts wird abgeschnitten, keine roten Overflow-Streifen

## Layout

- [ ] Handy hoch und quer
- [ ] Tablet hoch und quer
- [ ] Gerät mit Notch/Punch-Hole: nichts liegt unter der Aussparung oder der Gestenleiste

## Ausdauer

- [ ] 15–20 Minuten am Stück malen: keine spürbare Verlangsamung, kein Speicherproblem
- [ ] Ein sehr vollgemaltes Bild (viele Striche, viele Füllungen) bleibt flüssig
- [ ] App mehrfach in den Hintergrund und zurück; Akkuverbrauch bleibt im Rahmen

---

## Wenn etwas schiefgeht

**Zuerst der Problembericht in der App** (Einstellungen → „Problembericht", hinter der Elternschranke). Seit v7.5 schreibt die App jeden gefangenen Fehler dort hin — mit Zeitpunkt, Herkunft und gekürztem Stack. Das überlebt den App-Neustart und ist damit oft genau die Information, die nach „irgendwas war komisch" fehlt. „Bericht teilen" legt die Datei ins Share-Sheet.

Live mitlesen, während die App läuft:

```bash
flutter logs
```

Für einen Absturz mit vollem Stack ist der Debug-Build aussagekräftiger:

```bash
flutter run -d <geräte-id>
```

Bei allem, was reproduzierbar ist, hilft es, die genauen Schritte zu notieren — die meisten Fehler dieser Art lassen sich anschließend als Test festhalten, damit sie nicht zurückkommen.
