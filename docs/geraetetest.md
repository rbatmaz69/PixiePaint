# Gerätetest-Checkliste

Alles aus v6.1–v8.5 wurde gebaut, aber noch nie auf einem echten Gerät benutzt. Diese Liste ist für genau diese eine große Session gedacht: einmal von oben nach unten, mit einem Handy **und** einem Tablet.

Warum überhaupt eine Liste: Die Test-Suite deckt Logik und Beschriftungen ab, aber nichts von dem, was hier steht — Gesten, Druckstärke, Systemdialoge, Layout auf echten Seitenverhältnissen, Musik, Vibration. Und seit v8.4/v8.5 auch nichts davon, ob die Bewegung **angenehm** wirkt; das kann nur ein Mensch beurteilen.

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

**Wiederfinden** (neu in v8.2)

- [ ] Bild malen, verlassen → auf der Startseite steht oben „Weitermalen" mit dem Vorschaubild; antippen führt genau in dieses Bild
- [ ] Ein zweites Bild malen → die Karte zeigt jetzt das neuere
- [ ] Auf ein anderes Kind wechseln → die Karte zeigt dessen letztes Bild, oder verschwindet, wenn es noch keines hat
- [ ] Bildauswahl: Herz auf einer Kachel antippen → der Reiter „💖" erscheint ganz vorne und enthält das Bild
- [ ] Herz wieder abwählen → mit dem letzten Herz verschwindet der Reiter
- [ ] Lange auf eine Kachel drücken druckt weiterhin (Elternschranke), das Herz stört das nicht

**Fühlen und für alle** (neu in v8.3)

- [ ] Einstellungen → Spaß: „Vibrieren" ist ein eigener Schalter. Ton **aus**, Vibration **an** → Knöpfe fühlen sich weiterhin an
- [ ] Beides aus → gar keine Rückmeldung; beides an → wie gewohnt
- [ ] System-Einstellung „Animationen entfernen" (Android: Entwickleroptionen/Bedienungshilfen) bzw. „Bewegung reduzieren" (iOS) einschalten: Hintergrund-Blobs stehen still, Knöpfe federn nicht mehr, kein Konfetti — die Belohnungs-Sticker erscheinen trotzdem
- [ ] Systemschriftgröße auf das Maximum stellen: Startseite, Einstellungen, Bildauswahl und Malbereich bleiben heil (keine abgeschnittenen Texte, keine gelb-schwarzen Streifen)

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

## Design und Bewegung (neu in v8.4/v8.5)

Diese Runde hat nichts hinzugefügt, sondern das Vorhandene zusammengeführt. Was hier zu prüfen ist, ist deshalb vor allem: **wirkt es ruhig, oder wirkt es unruhig?**

- [ ] **Startseite öffnen:** die Karten kommen gestaffelt herein, nicht alle auf einmal und nicht ruckelnd
- [ ] Dieselbe Staffelung in Bildauswahl, Galerie, Nachspuren, Szenen, Erfolge-Album, Einstellungen, Speicher und Problembericht — überall gleich schnell, nirgends doppelt
- [ ] **Ausmalbild antippen:** das Bild fliegt in die Leinwand, statt dass der Bildschirm ausgetauscht wird. Kein Sprung, kein Zappeln, kein doppeltes Bild
- [ ] Derselbe Flug aus der Galerie, von der Weitermalen-Karte und aus der Szenenauswahl
- [ ] **Schatten anschauen** (Startseite, Galerie, Bildauswahl): liegen die Karten auf dem Papier, oder wirkt es zu schwer und schmutzig? → Zahl in `PixieTokens.softShadow`
- [ ] **Glanz anschauen**, vor allem auf den Szenen-Kacheln, die fast ganz Bild sind: liest sich das als Aufkleber oder als Schliere? → `StickerCard(sheen: false)` für diesen Fall
- [ ] Kopfzeilen: der farbige Strich unter dem Titel passt zur Farbe des jeweiligen Bildschirms
- [ ] **Malen:** Werkzeug wechseln — nur das *aufgenommene* hüpft, das abgelegte bleibt ruhig
- [ ] Farbe unten wechseln: der Farbpunkt am Werkzeug oben antwortet
- [ ] Mehrfach Rückgängig tippen: der Knopf antwortet auf **jeden** Tipp, zuckt aber **nicht**, während gemalt wird
- [ ] Die Papierstruktur hinter der Leinwand ist sichtbar, aber steht still und lenkt beim Malen nicht ab
- [ ] **Zeitraffer starten:** die Leiste unter dem Papier füllt sich gleichmäßig und kommt am Ende wirklich an. Tempo umschalten — die Zahl antwortet
- [ ] **Diashow starten:** die Punkte zeigen das richtige Bild, verschwinden nach drei Sekunden mit dem Schließen-Knopf und kommen bei Berührung zurück. Bei vielen Bildern wandert das Fenster mit
- [ ] **Zu zweit malen** (Tablet): beide Flächen liegen auf einem Blatt mit einem Falz dazwischen
- [ ] **Bild fertig malen** → großes Konfetti. **Bild teilen** → kleines. Der Unterschied muss auffallen
- [ ] Sticker freischalten: der Sticker wippt beim Aufkommen nach
- [ ] **„Bewegung reduzieren" im System einschalten** und alles noch einmal: nichts fliegt, nichts pulst, nichts driftet, kein Konfetti — die Belohnungen erscheinen aber weiterhin

## Bewegung und Einheitlichkeit (neu in v8.6)

Diese Runde hat der Bewegung Tokens gegeben und ein paar Stellen ergänzt. Die wichtigste Frage ist nicht „gefällt es", sondern: **fühlt sich Auswählen überall gleich an?** Vorher lief dieselbe Handlung an sieben verschiedenen Geschwindigkeiten.

- [ ] **Nacheinander antippen:** Werkzeug, Farbe, Form, Zauber-Spiegel, Sticker, Pinselgröße, Galerie-Filter, Kind-Profil. Alle acht müssen sich **gleich schnell** anfühlen. Fühlt sich eines davon zäh oder hektisch an, ist es die ganze Sprosse — dann `PixieMotion.select` verstellen, nicht die einzelne Stelle
- [ ] Die vier Auswahl-Blätter (Formen, Spiegel, Sticker, Füllmuster) waren mit 150 ms die schnellsten und sind jetzt bei 240. Wirkt das weich oder träge?
- [ ] **Farbe wechseln:** die weiße Schale gleitet von Feld zu Feld, statt zu verschwinden und woanders aufzutauchen. Sie muss dabei *unter* dem Farbfeld bleiben und beim seitlichen Scrollen mitwandern
- [ ] Eine Farbe über „Mehr Farben" mischen: die Schale landet auf dem zusätzlichen Feld ganz rechts
- [ ] **Ein Zahlenbild öffnen:** dieselbe Schale gleitet dort zwischen den nummerierten Feldern. Die Kachel selbst wächst nicht mehr mit — nur der *Hinweis* nach mehreren Fehlversuchen wippt noch groß heraus, und der Haken für „fertig" bleibt
- [ ] **Größen-Blatt öffnen:** Regler, Daumen und Aura tragen die aktuelle Malfarbe. Bei Weiß und Rosa bleibt der Regler trotzdem erkennbar
- [ ] **Eine ganz helle Farbe aus der obersten Reihe des Farb-Sheets wählen** (blassgelb, blassgrün): der Punkt auf dem Größenknopf in der Leiste behält seine dünne Kontur. Vorher bekam nur reines Weiß eine
- [ ] **Bildschirm-Hintergründe querlesen** (Startseite, Leinwand, Bildauswahl, Galerie, Foto): jeder hat unten noch seinen eigenen warmen Hauch — fünf Werte sind umgezogen, keiner sollte sich geändert haben
- [ ] **Einstellungen:** jeder eingeschaltete Schalter hat einen Haken im Daumen
- [ ] **Von der Startseite in einen Bildschirm gehen:** die Startseite tritt dabei zurück und dunkelt leicht ab — es gibt ein Vorne und ein Hinten. Beim Zurück umgekehrt
- [ ] **Ausmalbild antippen:** das Bild behält während des Fluges runde Ecken und einen Schatten. Vorher war es unterwegs ein nacktes Rechteck. Auch auf dem Rückweg prüfen
- [ ] **Startseite ansehen, ohne zu tippen:** die acht Karten atmen ganz langsam und *nicht* im Gleichtakt. Wenn es als „die Seite wackelt" liest, ist die Amplitude zu groß (`_BigCard`, derzeit ±2,5 px)
- [ ] **Startseite scrollen:** die Blobs im Hintergrund wandern langsamer als die Karten
- [ ] **Galerie mit vielen Bildern weit nach unten scrollen:** auch das vierzigste Bild schwebt herein, statt einfach da zu sein. Dasselbe in Bildauswahl, Erfolge-Album und Speicher
- [ ] **Abstände querlesen** (Startseite, Einstellungen, Dialoge): 92 Abstände wurden auf die Leiter gezogen, dabei wurden 31 um 2–4 px **enger**. Sieht irgendwo etwas gedrängt aus?
- [ ] Bei größter Systemschrift dieselben Bildschirme noch einmal — die Abstände wurden nur enger, es sollte also eher mehr passen als vorher
- [ ] **Teilen** (aus der Leinwand *und* aus der Galerie): beide geben jetzt dasselbe kleine Konfetti. Vorher warf die Leinwand die volle Party
- [ ] **„Bewegung reduzieren" im System einschalten:** Karten stehen still, keine Parallaxe, die Farbschale springt sofort an ihren Platz statt zu gleiten, Bildschirme blenden nur noch ein. Konfetti bleibt aus, die Belohnung selbst erscheint weiterhin

## Nichts geht verloren (neu in v8.7)

Diese Runde behebt vier Wege, auf denen Arbeit **stumm** verschwand. Die Frage beim Prüfen ist nicht „sieht es gut aus", sondern: **ist noch da, was ich gemalt habe?**

- [ ] **Mitten in einem langen Strich einen zweiten Finger auflegen** (Daumen der haltenden Hand). Der Strich muss **da bleiben** — vorher war er weg, ohne Ton und ohne Rückgängig. Danach einmal auf Rückgängig: er verschwindet, kommt mit Wiederholen zurück
- [ ] Dasselbe mit einer Form, die gerade aufgezogen wird
- [ ] Dasselbe mit einem Sticker, der noch nicht abgesetzt ist: der darf verfallen, es wurde ja nichts gezeichnet
- [ ] **Zwanzig Striche malen und dann zwanzigmal auf Rückgängig tippen.** Alle zwanzig müssen zurückgehen. Vorher war bei drei Schluss
- [ ] **Zwanzig Striche, App wegwischen, wiederkommen, zurückgehen.** Auch das muss weit zurückreichen — vorher blieb genau ein Schritt übrig
- [ ] **Ein paar Flutfüllungen dazwischen**, dann zurückgehen: die kosten weiterhin viel und werden irgendwann verworfen. Das ist in Ordnung — geprüft wird, dass nichts *falsch* zurückkommt, also keine Reste stehen bleiben und kein Fleck an der falschen Stelle sitzt
- [ ] **Beim Malen die Hand auflegen** (Tablet, flach auf dem Tisch): die Handfläche soll keinen Strich beginnen, die Fingerspitze danach schon. Auf Geräten, die die Kontaktfläche nicht messen, ändert sich nichts — dann ist dieser Punkt nicht prüfbar

## Nichts liegt im Bild, nichts endet im Nichts (neu in v8.7)

- [ ] **Hochformat, ganz oben ins Bild malen** — dort, wo vorher Zurück und Teilen lagen. Es muss ein Strich entstehen und kein Bildschirmwechsel. Beides auch **linkshändig** (Einstellungen) und im **Querformat**
- [ ] **Das weiße Blatt ansehen:** es hat jetzt genau die Form des Bildes. Ober- und unterhalb ist Hintergrund, kein Papier. Ein Tipp dort malt nichts — vorher entstand eine harte Linie am Bildrand
- [ ] **Der Dreh-Hinweis unten:** einen Strich beginnen, während er noch steht. Der Strich muss ankommen, statt als Wegtipp-Geste geschluckt zu werden
- [ ] **Zwei-Maler öffnen** (Tablet): Zurück und Umdrehen sitzen auf der Falz in der Mitte, nicht in einem der beiden Bilder
- [ ] **Erststart auf einem frisch installierten Gerät** (App-Daten löschen oder neu installieren): nach dem Willkommen kommt die Bildauswahl, und ihr Zurück-Pfeil führt auf die **Startseite**. Vorher war dort nichts, und Galerie, Erfolge, Profil und Einstellungen waren die ganze erste Sitzung lang unerreichbar
- [ ] **Zeitraffer eines Bildes öffnen** (Galerie, Kachel lange drücken → 🎬): solange geladen wird, ist ein Zurück-Pfeil da

## Jeder Tipp bekommt eine Antwort (neu in v8.7)

- [ ] **Mit dem Farbeimer genau auf eine Linie tippen:** ein leiser Ton und ein kleiner Ring an der Tippstelle. Vorher passierte gar nichts, was sich wie „kaputt" liest
- [ ] Zweimal an dieselbe Stelle füllen: beim zweiten Mal dieselbe kleine Antwort, und **kein** neuer Rückgängig-Schritt
- [ ] **Pipette ganz kurz antippen** (Finger sofort wieder hoch): die Farbe wird trotzdem übernommen und das vorherige Werkzeug kommt zurück. Vorher war ein kurzer Tipp ein toter Tipp
- [ ] **Alles löschen:** es gibt einen Ton, das Bild verschwindet nicht lautlos
- [ ] **Radiergummi absetzen:** ein leiser Ton bestätigt, dass etwas passiert ist
- [ ] **Größen-Blatt:** ein Tipp auf 🐜/🐈/🐘 schließt das Blatt wie jedes andere. Der Regler nicht — daran darf weiter gezogen werden

## Was da war, aber niemand fand (neu in v8.7)

Diese Runde hat keine Funktion ergänzt, sondern vorhandene erreichbar gemacht. Beim Testen geht es also weniger um „geht das?" als um „findet man das, ohne es zu wissen?".

- [ ] **Galerie:** unten rechts auf der Bildkarte sitzt ein Knopf mit drei Punkten. Er öffnet dasselbe Blatt wie das lange Drücken (Weitermalen, Film, Umbenennen, In Fotos, Teilen, Drucken, Wegwerfen)
- [ ] Ein Bild mit langem Namen: der Name läuft **nicht** unter den Knopf, auch nicht bei größter Systemschrift
- [ ] **Elternschranke:** eine Rechenaufgabe lösen, dann in der Galerie ein zweites Bild teilen — es wird **nicht** noch einmal gefragt. Nach etwa drei Minuten wieder schon
- [ ] **Malzeit-Pause** (Einstellungen → Malzeit): Wenn der Vorhang fällt, wird **immer** gefragt, auch wenn kurz vorher eine Aufgabe gelöst wurde. Das ist Absicht
- [ ] Dreimal falsch antworten: die App sagt es, statt sich wortlos zu schließen
- [ ] **Einstellungen → Sicherheit:** „Einfache Werkzeuge" steht jetzt hier und nennt das aktive Kind. Umlegen und ein Bild öffnen: die Leiste zeigt vier Werkzeuge
- [ ] **Einstellungen → Über:** „Begrüßung noch einmal" zeigt die drei Startkarten. Am Ende landet man **wieder in den Einstellungen**, nicht in der Bildauswahl
- [ ] **Erstes Zahlenbild öffnen:** eine Karte erklärt die Regel. Beim zweiten Zahlenbild nicht mehr
- [ ] **Erste Nachspur-Vorlage:** dasselbe mit dem grünen Startpunkt
- [ ] **Bildauswahl:** Zahlenbilder tragen unten links ein „1·2·3". Ein Bild malen, zurückgehen — die Kachel trägt jetzt oben links einen Stern
- [ ] Beide Marken bleiben bei größter Systemschrift klein (sie skalieren bewusst nicht mit)
- [ ] **Teilen, Drucken, In Fotos:** es erscheint eine „Einen Moment"-Karte, solange gerechnet wird
- [ ] **Drucken abbrechen oder ohne Drucker versuchen:** es kommt eine Meldung. Vorher passierte sichtbar nichts
- [ ] **Kind entfernen** (Profil → Verwalten): der Text nennt die Anzahl der Bilder. „Bilder auch löschen" fragt ein **zweites** Mal
- [ ] **Größte Systemschrift, irgendein Dialog mit zwei Sätzen:** der Knopf ist erreichbar — notfalls durch Scrollen im Dialog. Vorher fiel er unten heraus

## Konsistenz und Tablet (neu in v8.8)

Die sichtbarste Änderung der ganzen Runde steht zuerst.

- [ ] **Startseite auf dem Telefon:** die Karten stehen **zwei nebeneinander**. Vorher lag jede allein in ihrer Zeile, auf jedem Gerät — die Seite war doppelt so lang wie nötig
- [ ] **Startseite auf dem Tablet quer:** drei Karten pro Reihe, mittig, und „Weitermalen" sowie die Tagesaufgabe sind genauso breit wie das Kartenraster. Vorher waren das 1200 dp breite Bänder
- [ ] **Willkommen auf dem Tablet quer:** der Text läuft nicht mehr über die volle Fensterbreite
- [ ] **Malbildschirm, hoch und quer:** unter den Werkzeugknöpfen liegt **eine** weiße Fläche, nicht zwei übereinander
- [ ] **Zwei-Maler-Modus:** dort trägt die Knopfgruppe weiterhin ihr eigenes Weiß — sonst stünde sie auf nichts
- [ ] Werkzeuge, Größenknopf, Zauberspiegel und Rückgängig sind gleich breit — in der normalen Leiste und im Einfach-Modus
- [ ] Ecken: alle Sticker-Karten (Einstellungen, Speicher, Szenen, Bildauswahl, Album, Foto) haben denselben Radius
- [ ] **Farbpalette und Größen-Blatt:** ein helles Feld (Weiß, Hellgelb, Rosa) hat weiterhin eine sichtbare Kontur

**Geschmacksfrage fürs Gerät:** Die gleitende Auswahl-Schale, die es in beiden Paletten gibt, wurde für die Werkzeugleiste gebaut und wieder ausgebaut — auf der weißen Leiste ist eine weiße Schale unsichtbar. Falls die Auswahl in der Leiste zu leise wirkt, wäre der nächste Versuch eine **getönte** Schale statt einer weißen (`SelectionCradle`).

## Neue Werkzeuge (neu in v8.9)

- [ ] **Formen-Blatt:** acht Motive statt fünf. Linie, Dreieck und Ei sind neu
- [ ] **Linie:** sie folgt der Richtung, in die gezogen wurde — schräg ziehen ergibt eine schräge Linie
- [ ] Unten im Formen-Blatt: „Ausgemalt" / „Nur Rand". Umschalten ändert sofort die Vorschau auf allen Kacheln
- [ ] Ein Umriss behält die gewählte Farbe (eine ausgemalte Form bekommt eine dunklere Kante)
- [ ] **Buchstaben (🔤):** Namen tippen, aufs Bild tippen — das Wort hängt unter dem Finger und wird beim Loslassen gesetzt
- [ ] Mit eingeschaltetem Zauberspiegel: das Wort erscheint mehrfach, aber **lesbar**, nicht spiegelverkehrt
- [ ] Ein gesetztes Wort lässt sich in **einem** Schritt rückgängig machen — auch die letzten Buchstaben verschwinden
- [ ] **Eigener Sticker:** über dem Foto stehen drei Knöpfe (Kreis, Herz, Stern). Die Vorschau zeigt dieselbe Form, die anschließend herauskommt
- [ ] **Malgeräusch:** ein leises Geräusch beim Ansetzen eines Strichs. Schnell hintereinander tupfen rattert **nicht**
- [ ] Mit „Mal-Geräusche" aus ist es weg
- [ ] **Zeitraffer** eines Bildes mit Wort, Umriss und schräger Linie: der Film zeigt dasselbe wie das Bild

## Barrierefreiheit (neu in v6.7)

- [ ] **TalkBack (Android) bzw. VoiceOver (iOS) einschalten** und über die Startseite wischen — jede Kachel wird benannt
- [ ] Werkzeugleiste durchwischen: jedes Werkzeug wird benannt, das aktive zusätzlich als „ausgewählt"
- [ ] Farbpalette durchwischen: die Farben heißen „Rot", „Blau" usw., nicht 16-mal dasselbe
- [ ] **„Mehr Farben" öffnen und durch das große Raster wischen:** jedes Feld wird nach seiner Spalte benannt („Rot", „Türkis"), nicht 43-mal „Eigene Farbe". Eine Spalte trägt fünfmal denselben Namen — das ist gewollt, es sind fünf Rot
- [ ] **Eine Farbe mit der Pipette vom Bild aufnehmen:** sie wird mit dem nächstliegenden der sechzehn Namen angesagt. Der zusätzliche Platz ganz rechts in der Palette heißt weiterhin „Eigene Farbe", weil er das Sheet öffnet und keine Farbe wählt
- [ ] Der Malbereich wird als eine Fläche angesagt, nicht Pixel für Pixel
- [ ] Zeitraffer: der Tempo-Knopf wird benannt (war bis v8.5 für Screenreader gar nicht vorhanden)
- [ ] Diashow: die Punktreihe wird als „4 / 17" angesagt, nicht als Reihe namenloser Punkte
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
