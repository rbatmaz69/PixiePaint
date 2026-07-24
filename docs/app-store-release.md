# PixiePaint im Apple App Store veröffentlichen

Das iOS-Gegenstück zu [`play-store-release.md`](play-store-release.md). Schritte mit 👤 machst du selbst (Konto, Passwörter, Uploads).

> **Apples Kids-Kategorie ist strenger als Googles Familienrichtlinie.** Der wichtigste Unterschied: In der Kids Category sind Analytics und Werbe-SDKs von Drittanbietern **komplett verboten** (nicht nur eingeschränkt), und jeder Link nach draußen muss hinter einer Elternschranke liegen. PixiePaint erfüllt beides von Haus aus — die App hat kein einziges Netzwerk-SDK. Siehe Schritt 6.

## 1. 👤 Apple Developer Program

1. https://developer.apple.com/programs/ → Mitgliedschaft abschließen (99 $/Jahr)
2. Identitätsprüfung abwarten (kann mehrere Tage dauern)
3. In App Store Connect (https://appstoreconnect.apple.com) mit derselben Apple-ID anmelden

Ohne bezahlte Mitgliedschaft läuft die App nur 7 Tage auf einem angeschlossenen Gerät und lässt sich weder über TestFlight noch über den Store verteilen.

## 2. 👤 Signing einrichten

```bash
open ios/Runner.xcworkspace
```

In Xcode: **Runner → Signing & Capabilities**
- „Automatically manage signing" anhaken
- **Team** auswählen (dein Developer-Account)
- **Bundle Identifier** prüfen: `dev.rb.pixiepaint.pixiepaint`

Xcode legt das Provisioning-Profil dann selbst an. Ändert sich der Bundle Identifier später, muss er auch in App Store Connect derselbe sein — er lässt sich dort nach dem Anlegen **nicht mehr ändern**.

## 3. 👤 App in App Store Connect anlegen

„Meine Apps" → **+** → Neue App
- **Plattform:** iOS
- **Name:** PixiePaint (muss App-Store-weit eindeutig sein — falls vergeben: „PixiePaint – Malbuch")
- **Primäre Sprache:** Deutsch
- **Bundle-ID:** die aus Schritt 2
- **SKU:** frei wählbar, z. B. `pixiepaint-001`

Der App-Name im Store darf von `CFBundleDisplayName` abweichen — der Homescreen-Name kommt aus der Info.plist, der Store-Name aus App Store Connect. Beide stehen seit v7.4 auf `PixiePaint`; vorher schrieb die Info.plist „Pixiepaint" und die App hieß auf dem iPhone anders als auf Android.

## 4. Build hochladen

```bash
flutter build ipa --release
```

Ergebnis: `build/ios/ipa/*.ipa`

Hochladen auf einem von zwei Wegen:
- **Xcode Organizer:** `open ios/Runner.xcworkspace` → Product → Archive → Distribute App
- **Transporter** (kostenlos im Mac App Store): .ipa hineinziehen und „Deliver"

Nach dem Upload dauert die Verarbeitung in App Store Connect 10–60 Minuten, bevor der Build auswählbar ist.

> **Build-Nummer:** Apple lehnt einen Upload ab, wenn `CFBundleVersion` schon einmal verwendet wurde — auch bei sonst identischem Versionsnamen. Die Nummer kommt aus `version:` in der `pubspec.yaml` (der Teil nach dem `+`) und muss bei **jedem** Upload steigen, auch bei einem reinen Korrektur-Build.

## 5. 👤 TestFlight

Vor der Store-Prüfung lohnt sich immer ein TestFlight-Durchlauf:

1. App Store Connect → TestFlight → Build auswählen
2. Interne Tester (bis 100 Personen aus deinem Team) brauchen keine Apple-Prüfung und können sofort testen
3. Externe Tester (bis 10 000) erfordern eine kurze Beta-Prüfung durch Apple (meist 1 Tag)

Für die Beta-Prüfung wird eine „Beta App Description" und eine Kontakt-E-Mail verlangt.

## 6. 👤 Kids Category und App-Datenschutz

**Altersfreigabe.** App Store Connect → App-Informationen → Altersfreigabe bearbeiten. Alle Fragen mit „Nie"/„Nein" beantworten → Ergebnis **4+**.

**Kids Category.** Unter „App-Informationen" die Kategorie **Kinder → Alter 5 und jünger** wählen. Damit gelten zusätzlich:

- **Keine Drittanbieter-Analytics und keine Werbung.** Erfüllt: PixiePaint hat keine Netzwerkverbindung.
- **Keine Links nach draußen ohne Elternschranke.** Erfüllt: „App bewerten" ist der einzige Link und liegt im Eltern-Bereich hinter der Rechenaufgabe.
- **Keine Käufe ohne Elternschranke.** Erfüllt: Es gibt keine Käufe.
- **Keine Erhebung personenbezogener Daten.** Erfüllt.
- **Datenschutzerklärung ist Pflicht.** URL: `https://rbatmaz69.github.io/PixiePaint/privacy-policy` (GitHub Pages aktivieren wie in [`play-store-release.md`](play-store-release.md) Schritt 5 beschrieben).

**App-Datenschutz („Nutrition Label").** App Store Connect → App-Datenschutz → „Daten werden nicht erfasst" auswählen. Das ist für PixiePaint korrekt und die einzige Antwort, die zur App passt: keine Analytics, keine IDs, keine Accounts, keine Netzwerkaufrufe. Fotos werden ausschließlich lokal verarbeitet, und die Sicherungsdatei erzeugt der Nutzer selbst und teilt sie über das System-Share-Sheet.

Das gilt auch für den **Problembericht** aus v7.5 (Einstellungen → „Problembericht"): Die App schreibt gefangene Fehler in eine lokale Datei `errors.log` — ohne Geräte-IDs, ohne absolute Pfade, ohne Bildinhalte — und teilt sie nur, wenn ein Elternteil das hinter der Rechenaufgabe bewusst auslöst. Es ist kein Crash-Reporting-SDK im Sinne des Formulars („Diagnosedaten" bleibt also auf *nicht erfasst*), weil nichts übertragen wird.

**Berechtigungstexte.** Apple prüft, ob die Begründungen zum tatsächlichen Verhalten passen. In `ios/Runner/Info.plist` stehen:

| Schlüssel | Text | Wann er erscheint |
|---|---|---|
| `NSPhotoLibraryUsageDescription` | „Zum Auswählen eines Fotos zum Anmalen." | Foto-Import, hinter der Elternschranke |
| `NSPhotoLibraryAddUsageDescription` | „Zum Speichern deiner Bilder in Fotos." | „In Fotos speichern", hinter der Elternschranke |

## 7. 👤 Store-Eintrag

**Untertitel (max. 30 Zeichen):**
> Malbuch ohne Werbung

**Werbetext (max. 170 Zeichen, jederzeit änderbar):**
> Ausmalen, frei zeichnen, Sticker kleben und nach Zahlen malen – komplett offline, ohne Werbung und ohne Datensammlung.

**Beschreibung:** Der Text aus [`play-store-release.md`](play-store-release.md) Schritt 6 lässt sich unverändert übernehmen.

**Lokalisierungen.** Die App unterstützt neun Sprachen; App Store Connect verlangt die Store-Texte pro Sprache getrennt („+ Sprache hinzufügen" oben im Versions-Editor). Ohne gepflegten Eintrag zeigt Apple die Sprache der primären Region. Untertitel und Keywords sind pro Sprache eigene Felder und lohnen die meiste Sorgfalt — sie fließen in die Suche ein.

**Keywords (max. 100 Zeichen, kommagetrennt, ohne Leerzeichen):**
> malen,ausmalen,malbuch,kinder,kritzeln,zeichnen,sticker,kleinkind,offline,lernen

**Screenshots.** Apple verlangt sie pro Gerätegröße; die Pflichtgrößen sind aktuell 6,9" iPhone und 13" iPad (die übrigen Größen leitet Apple daraus ab). Inhaltlich derselbe Plan wie in [`play-store-release.md`](play-store-release.md) Schritt 6 — die Tablet-Aufnahmen dort entsprechen den iPad-Screenshots hier.

Am einfachsten im Simulator aufnehmen, weil er exakt die verlangten Auflösungen liefert:

```bash
open -a Simulator
flutter run --release -d <simulator-id>
# Aufnahme: ⌘S im Simulator, landet auf dem Schreibtisch
```

## 8. 👤 Zur Prüfung einreichen

1. Version anlegen, Build aus Schritt 4 auswählen
2. Store-Texte, Screenshots, Altersfreigabe und App-Datenschutz vollständig ausfüllen
3. „Zur Überprüfung senden"

Die Prüfung dauert meist 1–3 Tage; Apps in der Kids Category werden gelegentlich zusätzlich manuell auf Links und Käufe geprüft.

## Checkliste vor dem Upload

- [ ] Developer-Mitgliedschaft aktiv, Signing-Team in Xcode gesetzt
- [ ] `flutter analyze` ohne Befund, `flutter test` grün
- [ ] Build-Nummer in `pubspec.yaml` erhöht (Apple lehnt Wiederholungen ab)
- [ ] `flutter build ipa --release` erfolgreich
- [ ] Datenschutz-URL erreichbar
- [ ] App-Datenschutz auf „Daten werden nicht erfasst" gesetzt
- [ ] Kids Category und Altersfreigabe 4+ eingetragen
- [ ] Screenshots für 6,9" iPhone und 13" iPad
- [ ] Gerätetest-Checkliste abgearbeitet ([`geraetetest.md`](geraetetest.md)), besonders VoiceOver und Foto-Berechtigungen

## Technische Fakten (für die Formulare)

| | |
|---|---|
| Bundle Identifier | `dev.rb.pixiepaint.pixiepaint` |
| Version | 7.5.0 (Build 25) — maßgeblich ist immer `version:` in der `pubspec.yaml` |
| Berechtigungen | Fotobibliothek (Lesen und Sichern), beides hinter der Elternschranke |
| Netzwerk | keines |
| Tracking | keines (kein ATT-Dialog nötig) |
| In-App-Käufe | keine |
