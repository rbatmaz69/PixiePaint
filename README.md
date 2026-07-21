# 🎨 PixiePaint

Ein liebevolles Malbuch für Kinder ab 3 Jahren — komplett offline, ohne Werbung, ohne Datensammlung. Gebaut mit Flutter für Android und iOS.

**Aktuelle Version:** 6.0.0+8 · **Design-Sprache:** „Sticker-Buch" (bunte Sticker auf warmem Papier)

---

## Inhalt

- [Features](#features)
- [Voraussetzungen](#voraussetzungen)
- [Projekt einrichten](#projekt-einrichten)
- [App auf dem Gerät installieren](#app-auf-dem-gerät-installieren) ← Debug- & Release-Builds
- [Entwicklung](#entwicklung)
- [Tests & Codequalität](#tests--codequalität)
- [Übersetzungen (l10n)](#übersetzungen-l10n)
- [Projektstruktur](#projektstruktur)
- [Architektur-Notizen](#architektur-notizen)
- [Inhalte erweitern](#inhalte-erweitern)
- [Veröffentlichen](#veröffentlichen)
- [Datenschutz](#datenschutz)

---

## Features

**Malen**
- 32 Ausmalbilder in 6 Kategorien (Tiere, Fahrzeuge, Fantasie, Natur, Leckereien, Weltraum)
- Freies Zeichnen auf leerer Leinwand
- Eigene Fotos anmalen — oder per Kantenerkennung in ein Ausmalbild verwandeln
- 6 Stifte: Pinsel, Filzstift, Buntstift, Regenbogen, Glitzer, Neon
- Füllen mit 4 Mustern (einfarbig, Punkte, Streifen, Regenbogen), läuft in einem Isolate
- Formen aufziehen: Kreis, Quadrat, Herz, Stern, Regenbogen — mit Live-Vorschau
- 20 Emoji-Sticker + 9 freischaltbare Belohnungs-Sticker
- Pipette: Farbe direkt vom Bild aufnehmen
- Stufenlose Pinselgröße (8–90), Radierer, Undo/Redo
- Zwei-Finger-Zoom, Stift-Unterstützung mit Druckstärke, Handballen-Erkennung

**Galerie**
- Automatisches Speichern (alle 30 s und beim Verlassen)
- Favoriten, Umbenennen, Filter
- Teilen oder „In Fotos speichern" (beides hinter der Elternschranke)

**Belohnungen**
- Sticker freimalen: Bilder fertigstellen, Werkzeuge ausprobieren, ein Bild teilen
- Gesperrte Sticker als wackelnde Mystery-Boxen mit kindgerechter Fortschrittsanzeige
- Rein lokal — keine Käufe, keine Accounts

**Für Eltern**
- Elternschranke (Rechenaufgabe) vor Foto-Import, Teilen, Einstellungen und optional Löschen
- Keine Internetverbindung, keine Tracking-IDs, keine Datensammlung
- Deutsch und Englisch

---

## Voraussetzungen

| | Version |
|---|---|
| Flutter | 3.44.6 (stable) |
| Dart SDK | ^3.12.2 |
| Android | minSdk 24 (Android 7.0), Java 17 |
| iOS | Xcode mit gültigem Signing-Profil |

Prüfen, ob alles bereit ist:

```bash
flutter doctor -v
```

## Projekt einrichten

```bash
git clone https://github.com/rbatmaz69/PixiePaint.git
cd PixiePaint
flutter pub get
```

Das war's — die Lokalisierungs-Dateien (`lib/l10n/app_localizations*.dart`) sind eingecheckt und werden bei jedem Build ohnehin neu generiert (`generate: true` in der `pubspec.yaml`).

---

## App auf dem Gerät installieren

### Gerät finden

```bash
flutter devices
```

Ausgabe z. B. `SM_G990B (mobile) • R5CT30XXXXX • android-arm64 • Android 14 (API 34)`. Die mittlere Spalte ist die Geräte-ID für `-d`.

### Android

**Debug (mit Hot Reload — zum Entwickeln)**

```bash
flutter run -d R5CT30XXXXX
```

Läuft direkt auf dem Gerät und bleibt mit dem Terminal verbunden: `r` = Hot Reload, `R` = Hot Restart, `q` = beenden.

Voraussetzung am Gerät: Entwickleroptionen aktiv (7× auf „Buildnummer" in den Telefon-Einstellungen tippen) und **USB-Debugging** an.

**Release (optimiert — zum echten Ausprobieren)**

```bash
# Baut und installiert in einem Rutsch
flutter run --release -d R5CT30XXXXX
```

**Release-APK bauen und dauerhaft installieren**

```bash
flutter build apk --release
flutter install --release -d R5CT30XXXXX
```

Die fertige Datei liegt unter `build/app/outputs/flutter-apk/app-release.apk` und lässt sich auch direkt per `adb` installieren oder aufs Gerät kopieren:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Kleinere APKs (eine pro CPU-Architektur, rund ein Drittel der Größe):

```bash
flutter build apk --release --split-per-abi
# ergibt u. a. app-arm64-v8a-release.apk — das braucht fast jedes moderne Gerät
```

> **Signierung:** Ohne die Datei `android/key.properties` wird der Release-Build mit dem Debug-Schlüssel signiert. Zum lokalen Testen ist das völlig in Ordnung — für den Play Store **nicht**. Details in [`docs/play-store-release.md`](docs/play-store-release.md).

> **Wechsel zwischen Debug und Release:** Beide Varianten sind unterschiedlich signiert, deshalb verweigert Android die Installation über die jeweils andere („INSTALL_FAILED_UPDATE_INCOMPATIBLE"). Vorher deinstallieren:
> ```bash
> adb uninstall dev.rb.pixiepaint
> ```
> Damit sind allerdings auch alle gemalten Bilder weg.

### iOS

**Debug auf einem angeschlossenen iPhone/iPad**

```bash
open ios/Runner.xcworkspace   # einmalig: Signing-Team unter „Runner → Signing & Capabilities" setzen
flutter run -d <geräte-id>
```

**Release**

```bash
flutter run --release -d <geräte-id>
```

**IPA für TestFlight/App Store**

```bash
flutter build ipa --release
# Ergebnis: build/ios/ipa/*.ipa — Upload über Xcode Organizer oder Transporter
```

> Mit einer kostenlosen Apple-ID (ohne Developer-Programm) läuft die App nur 7 Tage auf dem Gerät und muss danach neu installiert werden.

### Simulator / Emulator

```bash
open -a Simulator                          # iOS-Simulator starten
flutter emulators --launch <emulator-id>   # Android-Emulator starten
flutter run
```

---

## Entwicklung

```bash
flutter run                        # erstes verfügbares Gerät, Debug-Modus
flutter run --profile              # Performance-Messungen (DevTools)
flutter clean && flutter pub get   # wenn der Build sich seltsam verhält
```

Nützlich im laufenden `flutter run`:

| Taste | Wirkung |
|---|---|
| `r` | Hot Reload |
| `R` | Hot Restart (State geht verloren) |
| `p` | Layout-Hilfslinien ein/aus |
| `o` | Zwischen Android- und iOS-Optik umschalten |
| `q` | Beenden |

## Tests & Codequalität

```bash
flutter analyze     # Linter (flutter_lints) — muss fehlerfrei sein
flutter test        # alle Unit-Tests
flutter test test/shape_renderer_test.dart   # einzelne Datei
```

Die Test-Suite (12 Dateien in `test/`) deckt bewusst nur **pure Logik** ab — Flood Fill, Undo-Stack, Formen-Geometrie, Farb-Utils, Kantenerkennung, Belohnungs-Regeln, Wackel-Mathematik, Viewport-Berechnung. UI und Animationen werden am Gerät geprüft; es gibt keine Golden Tests.

## Übersetzungen (l10n)

Deutsch ist die Ausgangssprache, Englisch die Übersetzung.

1. Neuen Text in `lib/l10n/app_de.arb` **und** `lib/l10n/app_en.arb` eintragen (gleicher Key)
2. Generieren:
   ```bash
   flutter gen-l10n
   ```
3. Im Code verwenden: `context.l10n.meinNeuerKey` (Helfer aus `lib/l10n/l10n.dart`)

Platzhalter und Pluralformen folgen dem ICU-Format — Beispiele stehen bei `gateQuestion` und `rewardRulePaintings` in den ARB-Dateien.

## Projektstruktur

```
lib/
├── main.dart              App-Start: System-UI, Settings & Fortschritt laden, Sfx init
├── app.dart               MaterialApp, Theme, RouteObserver
├── canvas/                Der Malbereich
│   ├── canvas_screen.dart     Bildschirm: Layouts, Autosave, Teilen, Belohnungs-Feier
│   ├── canvas_controller.dart Zentraler State: Ebenen, Zeiger, Werkzeuge, Undo
│   ├── canvas_painter.dart    Zeichnet Ebenen + Vorschauen
│   ├── stroke_renderer.dart   Die 6 Stift-Charaktere
│   ├── shape_renderer.dart    Formen-Geometrie
│   ├── flood_fill.dart        Füll-Algorithmus (läuft im Isolate)
│   └── *_burst.dart           Füll- und Stempel-Effekte
├── gallery/               Startseite, Ausmalbild-Auswahl, Galerie, Speicher
├── photo/                 Foto → Ausmalbild (Kantenerkennung)
├── settings/              Einstellungen
├── models/                Werkzeuge, Sticker, Belohnungen, Artwork, Ausmalbilder
├── ui/                    Design-System (siehe unten)
├── util/                  Settings, Fortschritt, Sfx, Bild-IO, Teilen, Speichern
├── widgets/               Werkzeugleiste, Farbpalette, Picker, Elternschranke
└── l10n/                  ARB-Dateien + generierte Übersetzungen

assets/
├── coloring_pages/        32 SVGs + pages.json (Katalog)
├── fonts/                 Fredoka (Medium/SemiBold/Bold)
├── sounds/                pop, tick, tada
└── icon/                  App-Icon & Splash

docs/                      Play-Store-Anleitung, Datenschutzerklärung
```

## Architektur-Notizen

**Design-System** (`lib/ui/`) — die Sticker-Buch-Sprache:
- `pixie_palette.dart` — **die eine** Farbquelle. Jeder UI-Ton leitet sich hiervon ab. (Die Malfarben in `widgets/color_palette.dart` sind bewusst getrennt: das ist Inhalt, keine Oberfläche.)
- `app_theme.dart` — Tokens (Radien, `softShadow`, `stickerTilt`), Gradients, Typo-Skala, Component-Themes
- `sticker.dart` — `StickerCard`, `StickerCircleButton`, `StickerEmoji`, `stickerSelectionDecoration`
- `pixie_header.dart` — einheitlicher Screen-Kopf (ersetzt AppBars)
- `bouncy.dart`, `pop_in.dart` — Bewegungs-Primitive (Press-Feder, Entrance-Pop, Puls)
- `blob_background.dart` — driftende Blobs + Doodles auf **einem** 28-s-Ticker, der sich automatisch pausiert, sobald die Route verdeckt oder die App im Hintergrund ist
- `kid_dialog.dart`, `kid_sheet.dart`, `reward_reveal.dart` — Dialoge, Sheets, Belohnungs-Moment

**Canvas-Performance:** Der `CanvasController` trennt zwei Signale — `repaint` (ValueNotifier, feuert bei jedem Zeichen-Sample und lässt nur den Painter neu malen) und `notifyListeners()` (nur für Werkzeugleisten-State). Der `CustomPaint` liegt in einer eigenen `RepaintBoundary`. **Neue Effekte im Malbereich gehören als Geschwister-Overlay daneben, niemals hinein** — Vorbild: `fill_burst.dart` und `stamp_burst.dart`.

**Persistenz:** Alles lokal, keine Datenbank.
- Bilder: ein Ordner je Werk unter `<appDocuments>/artworks/<uuid>/` mit `paint.png`, `thumb.png`, `meta.json` (plus optional Foto-Hintergrund und Linienart)
- Einstellungen: `settings.json`
- Belohnungs-Fortschritt: `progress.json`

## Inhalte erweitern

**Neues Ausmalbild hinzufügen**

1. SVG nach `assets/coloring_pages/` legen — geschlossene Konturen, schwarze Linien auf transparentem Grund, sonst „läuft" die Füllung aus
2. Eintrag in `assets/coloring_pages/pages.json` ergänzen:
   ```json
   {
     "id": "cat",
     "title": "Katze",
     "titleEn": "Cat",
     "file": "cat.svg",
     "category": "Tiere",
     "categoryEn": "Animals"
   }
   ```
   Die deutsche `category` ist der stabile Schlüssel — an ihr hängen die Pastell-Tints im Picker (`_categoryTint` in `lib/gallery/page_picker_screen.dart`).
3. `flutter run` — Assets werden über den Ordner-Eintrag in der `pubspec.yaml` automatisch mitgenommen

**Neuen Sticker** in `lib/models/stamp.dart` (`kStamps`) eintragen, **neue Belohnung** in `lib/models/reward.dart` (`kRewards`). Dort steht auch der Hinweis, welche Emoji plattformübergreifend farbig rendern.

## Veröffentlichen

Die komplette Schritt-für-Schritt-Anleitung für den Play Store (Keystore, App-Bundle, Formulare, Store-Texte) steht in **[`docs/play-store-release.md`](docs/play-store-release.md)**.

Kurzfassung:

```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```

Die Versionsnummer wird in der `pubspec.yaml` gepflegt: `version: 6.0.0+8` bedeutet Versionsname 6.0.0 und versionCode 8. Beide müssen bei jedem Store-Upload erhöht werden.

## Datenschutz

PixiePaint sammelt **keine** Daten. Alles bleibt auf dem Gerät: keine Internetverbindung, keine Analytics, keine Werbe-IDs, keine Accounts. Fotos werden ausschließlich lokal verarbeitet. Die vollständige Erklärung: [`docs/privacy-policy.md`](docs/privacy-policy.md).

| | |
|---|---|
| Android applicationId | `dev.rb.pixiepaint` |
| iOS Bundle Identifier | `dev.rb.pixiepaint.pixiepaint` |
| Berechtigungen | Fotobibliothek — nur beim Foto-Import bzw. -Export, jeweils hinter der Elternschranke |
| Internet | nein |
