# PixiePaint im Google Play Store veröffentlichen

Schritt-für-Schritt-Anleitung. Schritte mit 👤 machst du selbst (Konto, Passwörter, Uploads); alles andere ist im Repo schon vorbereitet.

## 1. 👤 Google-Play-Entwicklerkonto anlegen

1. https://play.google.com/console → mit Google-Konto anmelden
2. Einmalig 25 $ Registrierungsgebühr zahlen
3. Identitätsprüfung abschließen (kann 1–2 Tage dauern)

## 2. 👤 Upload-Keystore erzeugen (einmalig)

Im Terminal:

```bash
keytool -genkey -v -keystore ~/pixiepaint-upload.jks -keyalg RSA -keysize 2048 -validity 10950 -alias upload
```

Du wirst nach einem Passwort und ein paar Angaben (Name reicht) gefragt.

**WICHTIG – Backup:** Speichere die Datei `~/pixiepaint-upload.jks` UND das Passwort an zwei sicheren Orten (Passwort-Manager + z. B. USB-Stick). Ohne den Keystore kannst du keine Updates mehr hochladen. (Dank „Play App Signing" verwaltet Google den eigentlichen App-Schlüssel; das hier ist nur der Upload-Schlüssel – er lässt sich im Notfall über den Play-Support zurücksetzen, aber das dauert.)

Dann die Datei `android/key.properties` anlegen (liegt in .gitignore, landet also nie auf GitHub):

```properties
storeFile=/Users/rb/pixiepaint-upload.jks
storePassword=DEIN_PASSWORT
keyAlias=upload
keyPassword=DEIN_PASSWORT
```

## 3. Technische Prüfungen vor dem Upload

Play verschärft seine Anforderungen jedes Jahr, und die konkreten Zahlen ändern sich. Deshalb hier als **Prüfschritte**, nicht als feste Werte — die verbindliche Zahl steht immer in der Play Console unter „App-Bundle-Explorer" bzw. in den Richtlinien-Hinweisen, die dir beim Upload angezeigt werden.

**a) Ziel-API-Level.** PixiePaint setzt keine eigene `targetSdkVersion`, sondern erbt sie aus dem Flutter-SDK (`flutter.targetSdkVersion` in `android/app/build.gradle.kts`). Auslesen:

```bash
grep -r "targetSdkVersion" $(dirname $(dirname $(readlink -f $(which flutter))))/packages/flutter_tools/gradle/
```

Ist der geerbte Wert niedriger als von Play gefordert, lässt er sich in `android/app/build.gradle.kts` überschreiben:

```kotlin
defaultConfig {
    targetSdk = 36   // statt flutter.targetSdkVersion
}
```

Nach jeder Änderung auf einem echten Gerät gegentesten — höhere Ziel-Level verschärfen Berechtigungen und Hintergrund-Regeln.

**b) 16-KB-Speicherseiten.** Neuere Android-Geräte nutzen 16-KB-Pages; native Bibliotheken müssen entsprechend ausgerichtet sein. PixiePaint selbst enthält keinen nativen Code, wohl aber einige Plugins. Nach dem Bau prüfen:

```bash
unzip -o build/app/outputs/bundle/release/app-release.aab -d /tmp/aab >/dev/null && find /tmp/aab -name "*.so" -exec sh -c 'echo "== $1"; objdump -p "$1" | grep -i "LOAD.*align" | head -2' _ {} \;
```

Ein `2**14` (= 16384) in der Ausrichtung ist gut. Bei Treffern mit `2**12` hilft in der Regel ein Update des betroffenen Plugins.

**c) Flutter aktuell halten.** `flutter --version` und `flutter doctor -v` prüfen; ein veraltetes SDK ist die häufigste Ursache für beide Punkte oben.

**d) Kotlin-Gradle-Plugin (offener Punkt, Stand v7.4.2).** Der Release-Build meldet:

> WARNING: Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): flutter_file_dialog, in_app_review
> Future versions of Flutter will fail to build if your app uses plugins that apply KGP.

Heute ist das nur eine Warnung — das Bundle entsteht normal. **Beide Plugins sind bereits auf ihrer neuesten Version** (`flutter_file_dialog` 3.3.1, `in_app_review` 2.0.12), es lässt sich also nicht durch ein Update beheben. Vor einem größeren Flutter-Upgrade deshalb nachsehen, ob die Pakete inzwischen auf „Built-in Kotlin" migriert sind; falls nicht, sind das die Ausweichwege:

- `flutter_file_dialog` wird nur für das Zurückholen einer Sicherung gebraucht (`lib/settings/settings_screen.dart`). Ersetzbar, sobald `file_picker` seinen win32-Konflikt mit `share_plus`/`wakelock_plus` los ist — der Grund für die Wahl steht in der `pubspec.yaml`.
- `in_app_review` treibt nur „App bewerten" in den Einstellungen. Im Notfall verzichtbar bzw. durch einen Store-Link ersetzbar.

## 4. App-Bundle bauen

```bash
flutter build appbundle --release
```

Ergebnis: `build/app/outputs/bundle/release/app-release.aab`

Hinweis: Ohne `key.properties` baut der Befehl trotzdem (Debug-Signatur als Fallback) – so eine .aab akzeptiert der Play Store aber **nicht**. Für Uploads muss `key.properties` existieren.

**Fehler „Release app bundle failed to strip debug symbols"?** Die .aab ist dann trotzdem fertig gebaut und signiert (liegt am Ergebnispfad oben) – Flutter kann nur seine Kontroll-Prüfung nicht ausführen, weil im Android SDK die „Command-line Tools" fehlen (`flutter doctor` zeigt das an). Dauerhaft beheben: Android Studio → Settings → Languages & Frameworks → Android SDK → Tab „SDK Tools" → Haken bei **„Android SDK Command-line Tools (latest)"** → Apply. Alternativ baut `cd android && ./gradlew bundleRelease` das Bundle direkt ohne diese Prüfung.

## 5. Datenschutzerklärung veröffentlichen

Play verlangt eine öffentliche Datenschutz-URL (besonders für Kinder-Apps). Im Repo ist alles dafür vorbereitet (`docs/_config.yml`, `docs/index.md`, Front-Matter in `docs/privacy-policy.md`) — es fehlt nur der Schalter:

1. 👤 GitHub-Repo → **Settings → Pages** → Source „Deploy from a branch" → Branch `main`, Ordner `/docs` → **Save**. Der erste Build dauert eine bis zwei Minuten.
2. Die Adressen sind dann:
   - Startseite: `https://rbatmaz69.github.io/PixiePaint/`
   - **Datenschutzerklärung: `https://rbatmaz69.github.io/PixiePaint/privacy-policy/`**
3. Diese URL in der Play Console unter „Datenschutzerklärung" eintragen (und in App Store Connect, siehe [`app-store-release.md`](app-store-release.md))

> **Der Schrägstrich am Ende ist der richtige.** Die Seite hat `permalink: /privacy-policy/`; GitHub leitet die Variante ohne Schrägstrich dorthin um, aber eintragen sollte man die kanonische.

> **Warum das nicht von allein funktioniert hätte:** GitHub Pages baut mit Jekyll, und Jekyll verarbeitet eine `.md`-Datei nur, wenn sie YAML-Front-Matter hat — sonst kopiert es sie unverändert durch, und die URL liefert eine 404 (bzw. rohes Markdown zum Herunterladen). Die Datei hat jetzt Front-Matter; wer hier eine Seite ergänzt, gibt ihr auch eine.

> Die drei internen Anleitungen in diesem Ordner (diese hier, `app-store-release.md`, `geraetetest.md`) sind in `_config.yml` unter `exclude:` aufgeführt und werden **nicht** als Website ausgeliefert. Im öffentlichen Repo bleiben sie natürlich lesbar.

## 6. 👤 App in der Play Console anlegen

„App erstellen" →
- **Name:** PixiePaint – Malbuch für Kinder
- **Standardsprache:** Deutsch
- **Typ:** App, **kostenlos**

### Store-Eintrag (Texte zum Kopieren)

**Kurzbeschreibung (max. 80 Zeichen):**
> Malbuch für Kinder: Ausmalen, Zeichnen, Sticker – ohne Werbung, ganz offline.

**Vollständige Beschreibung:**
> 🎨 PixiePaint ist ein liebevolles Malbuch für Kinder ab 3 Jahren.
>
> **Malen**
> • 68 Ausmalbilder: Tiere, Fahrzeuge, Fantasie, Natur, Leckereien, Weltraum, Bauernhof, Jahreszeiten
> • Flächen füllen per Fingertipp – einfarbig, Punkte, Streifen, Regenbogen, Herzen, Sterne, Karo oder Seifenblasen
> • Freies Zeichnen auf leerer Leinwand
> • Eigene Fotos anmalen oder in ein Ausmalbild verwandeln
> • 9 Stifte: Pinsel, Filzstift, Buntstift, Regenbogen, Glitzer, Neon, Herzchen-Spur, Punkte-Stift und Doppellinie
> • Formen aufziehen: Kreis, Quadrat, Herz, Stern, Regenbogen
> • Zauber-Spiegel: alles doppelt, vierfach oder sechsfach gespiegelt malen
> • 20 lustige Sticker-Stempel zum Freimalen – oder eigene Sticker aus eigenen Bildern basteln
> • Pipette, stufenlose Pinselgröße, Zwei-Finger-Zoom
> • Stift-Unterstützung mit Druckstärke (S Pen & Co.)
>
> **Immer wieder etwas Neues**
> • Malen nach Zahlen: nummerierte Flächen ausmalen und ein Bild entstehen sehen
> • Nachspuren: Buchstaben, Zahlen und Formen mit dem Finger nachfahren
> • Sticker-Welt: acht Szenen zum Bekleben und Weitermalen
> • Zu zweit malen: zwei Malflächen nebeneinander auf dem Tablet
> • Zeitraffer: jedes Bild lässt sich als kleiner Film noch einmal anschauen
> • Aufgabe des Tages: jeden Tag ein neuer Mal-Impuls, mit Serien-Zähler
> • Jahreszeiten: Bilder zu Weihnachten, Ostern, Sommer, Herbst und Halloween – passend zum Kalender ganz vorne
> • Erfolge-Album: alle gesammelten Sticker auf einen Blick
>
> **Galerie**
> • Automatisches Speichern – kein Bild geht verloren
> • Benennen, favorisieren, weitermalen
> • Diashow aller Bilder
> • Teilen, drucken oder in die Fotos speichern (hinter der Elternschranke)
>
> 👨‍👩‍👧 **Für Eltern**
> • Komplett offline – keine Internetverbindung, keine Werbung
> • Keine In-App-Käufe, keine Datensammlung, keine Accounts
> • Bis zu 4 Kinder-Profile mit eigenen Bildern und eigenem Fortschritt
> • Alle Bilder als Sicherungsdatei speichern – und wieder zurückholen
> • Speicherplatz einsehen und alte Bilder gezielt aufräumen
> • Elternschranke vor Foto-Import, Teilen, Drucken, Einstellungen und Löschen
> • Malzeit-Pause: nach 20, 30 oder 45 Minuten ein freundlicher Pausen-Hinweis
> • Linkshänder-Modus, „nur mit Stift malen", Töne und Musik abschaltbar
> • Für Screenreader beschriftet (TalkBack)
> • In neun Sprachen

### Sprachen im Store-Eintrag

Die App gibt es in neun Sprachen (Deutsch, Englisch, Französisch, Italienisch, Niederländisch, Polnisch, Portugiesisch, Spanisch, Türkisch). Play zeigt Store-Einträge nur in Sprachen an, die dort **einzeln gepflegt** sind — die Übersetzung in der App reicht dafür nicht.

Unter „Store-Eintrag → Übersetzungen verwalten" pro Sprache Kurzbeschreibung und Beschreibung hinterlegen. Die Texte oben sind auf Deutsch; für die übrigen Sprachen genügt eine sinngemäße Übersetzung derselben Punkte. Screenshots dürfen sprachübergreifend dieselben bleiben, solange kein Text darin steht.

Reihenfolge nach Aufwand-Nutzen: zuerst Englisch (Standard-Fallback für alle nicht gepflegten Sprachen), dann Spanisch, Französisch, Türkisch, Portugiesisch, Italienisch, Polnisch, Niederländisch.

- **Kategorie:** Lernen (oder Kunst & Design)
- **Grafiken:** erzeugt ein Befehl (seit v7.7):

  ```bash
  python3 tool/make_store_graphics.py
  ```

  Ergebnis in `build/store/`: `play_icon_512.png` (512 × 512, ohne Transparenz), `play_feature_graphic_1024x500.png` und `appstore_icon_1024.png` für den App Store. Die Feature-Grafik entsteht aus den echten Ausmalbildern, der Fredoka-Schrift und den Palette-Tönen der App — wenn sich das Icon oder die Farben ändern, ist derselbe Befehl die Aktualisierung. Voraussetzungen: `brew install librsvg` und Pillow.

  **Vor dem Hochladen ansehen.** Die drei Dateien sind reine Optik; kein Test kann beurteilen, ob sie gut aussehen.
- **Screenshots:** siehe unten

### Screenshot-Plan

Play verlangt mindestens 2 Handy-Screenshots; für die Tablet-Auszeichnung zusätzlich 7"- und 10"-Aufnahmen. Diese acht decken die App gut ab — die ersten drei sind die wichtigsten, weil nur sie in der Suchergebnis-Vorschau erscheinen:

| # | Bildschirm | Was drauf sein soll | Gerät |
|---|---|---|---|
| 1 | Malbereich mit einem halb ausgemalten Tier | Werkzeugleiste und Farbpalette gut sichtbar | Handy, hoch |
| 2 | Startseite | Die Kacheln aller Spielarten | Handy, hoch |
| 3 | Bildauswahl | Volles Raster, zeigt die Bandbreite der Motive | Handy, hoch |
| 4 | Malen nach Zahlen | Nummerierte Flächen, teilweise gefüllt | Handy, hoch |
| 5 | Nachspur-Modus | Ein Buchstabe zur Hälfte nachgespurt | Handy, hoch |
| 6 | Galerie | Mehrere fertige Bilder, eines als Favorit | Handy, hoch |
| 7 | Zwei-Maler-Modus | Beide Seiten bemalt | Tablet, quer |
| 8 | Sticker-Welt | Eine Szene mit aufgeklebten Stickern | Tablet, quer |

Aufnehmen am einfachsten während der Gerätetest-Session (siehe [`geraetetest.md`](geraetetest.md)) — dann sind die Bilder ohnehin echt gemalt und nicht gestellt.

## 7. 👤 Formulare in der Play Console

- **Datenschutzerklärung:** URL aus Schritt 5

- **App-Inhalte → Zielgruppe und Inhalte:** „Für Familien entwickelt", Zielgruppe inkl. unter 13. Alle Fragen wahrheitsgemäß: keine Werbung, keine Käufe, keine Datenerhebung, kein soziales Element, keine nutzergenerierten Inhalte, die andere sehen können.

- **Familienrichtlinie.** Bei Apps für Kinder prüft Google strenger und länger. Was für PixiePaint gilt und beim Ausfüllen hilft:
  - *Keine Werbung, keine Werbe-SDKs, keine Werbe-ID.* Die App enthält kein einziges Netzwerk-SDK.
  - *Keine Datenerhebung.* Es gibt keine Analytics, keine Crash-Reporter, keine Accounts.
  - *Keine externen Links.* Die einzige Ausnahme ist „App bewerten", das den Play Store öffnet — und das sitzt im Eltern-Bereich hinter der Rechenaufgabe.
  - *Keine In-App-Käufe.* Belohnungs-Sticker werden ausschließlich durch Malen freigeschaltet, nie gekauft.
  - *Elternschranke.* Alles, was die App verlässt (Teilen, Drucken, In Fotos speichern, Foto-Import) oder etwas löscht, liegt hinter einer Multiplikationsaufgabe. Google akzeptiert das als „age screen" für solche Aktionen.
  - *Foto-Zugriff.* Der Import läuft über den System-Picker; die App fordert keine dauerhafte Galerie-Berechtigung an.
  - *Systembackup.* Die App setzt kein `android:allowBackup="false"`, das Android-Systembackup darf ihre Daten also in das Google-Konto sichern. Das ist Absicht — so überleben die Bilder eines Kindes einen Gerätewechsel — und steht auch so in der Datenschutzerklärung. Für das Datensicherheits-Formular ändert es nichts: die Sicherung macht das Betriebssystem, nicht die App, und die App selbst erhebt und überträgt weiterhin nichts.

- **Datensicherheit-Formular:** „Es werden keine Nutzerdaten erhoben" und „keine Daten weitergegeben". Das stimmt: alles bleibt auf dem Gerät, Fotos werden nur lokal verarbeitet. Die Sicherungsdatei erzeugt der Nutzer selbst und teilt sie über das System-Share-Sheet — die App lädt nichts hoch. Dasselbe gilt für den Problembericht aus v7.5: er wird lokal in `errors.log` geschrieben, enthält keine Geräte-IDs und keine Pfade, und verlässt das Gerät nur, wenn ein Elternteil ihn hinter der Rechenaufgabe bewusst teilt. Es gibt weiterhin kein Analytics- und kein Crash-SDK.

- **Content-Rating-Fragebogen:** keine Gewalt, keine Sexualität, keine Schimpfwörter, keine Drogen, keine Nutzerinteraktion, keine Standortweitergabe → erwartetes Ergebnis: USK 0 / PEGI 3

- **Werbe-ID:** Nein, App verwendet keine Werbe-ID

## 8. 👤 Hochladen & veröffentlichen

1. Produktion → oder besser zuerst „Interner Test" → Neuer Release
2. `app-release.aab` hochladen
3. Release-Notizen: „Erste Veröffentlichung 🎨"
4. Prüfen & veröffentlichen. Die Google-Prüfung dauert bei Kinder-Apps meist einige Tage

## Checkliste vor dem Upload

- [ ] `key.properties` vorhanden, Keystore gesichert
- [ ] `flutter analyze` ohne Befund, `flutter test` grün
- [ ] Ziel-API-Level und 16-KB-Ausrichtung geprüft (Schritt 3)
- [ ] Version in `pubspec.yaml` erhöht (Name **und** Build-Nummer)
- [ ] `flutter build appbundle --release` erfolgreich
- [ ] GitHub Pages aktiv (Settings → Pages → `main` / `/docs`), `https://rbatmaz69.github.io/PixiePaint/privacy-policy/` erreichbar
- [ ] `python3 tool/make_store_graphics.py` gelaufen, die drei Dateien in `build/store/` angesehen
- [ ] Screenshots nach Plan aufgenommen
- [ ] Gerätetest-Checkliste abgearbeitet ([`geraetetest.md`](geraetetest.md))

## Technische Fakten (für die Formulare)

| | |
|---|---|
| applicationId | `dev.rb.pixiepaint` |
| Version | 7.7.0 (versionCode 27) — maßgeblich ist immer `version:` in der `pubspec.yaml` |
| minSdk | 24 (Android 7.0) |
| targetSdk | geerbt aus dem Flutter-SDK, siehe Schritt 3 |
| Berechtigungen | Fotobibliothek (Import über den System-Picker, Export via MediaStore); `WRITE_EXTERNAL_STORAGE` nur bis API 29 |
| Internet | nein |
| Sprachen | 9 (de, en, es, fr, it, nl, pl, pt, tr) |
| Werbung/Tracking | nein |
| In-App-Käufe | nein |
