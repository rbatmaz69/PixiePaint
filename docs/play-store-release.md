# PixiePaint im Google Play Store veröffentlichen

Schritt-für-Schritt-Anleitung. Schritte mit 👤 machst du selbst (Konto, Passwörter, Uploads); alles andere ist im Repo schon vorbereitet.

## 1. 👤 Google-Play-Entwicklerkonto anlegen

1. https://play.google.com/console → mit Google-Konto anmelden
2. Einmalig 25 $ Registrierungsgebühr zahlen
3. Identitätsprüfung abschließen (kann 1–2 Tage dauern)

## 2. 👤 Upload-Keystore erzeugen (einmalig)

Im Terminal:

```bash
keytool -genkey -v -keystore ~/pixiepaint-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10950 -alias upload
```

Du wirst nach einem Passwort und ein paar Angaben (Name reicht) gefragt.

**WICHTIG – Backup:** Speichere die Datei `~/pixiepaint-upload.jks` UND das Passwort an zwei sicheren Orten (Passwort-Manager + z.B. USB-Stick). Ohne den Keystore kannst du keine Updates mehr hochladen. (Dank „Play App Signing" verwaltet Google den eigentlichen App-Schlüssel; das hier ist nur der Upload-Schlüssel – er lässt sich im Notfall über den Play-Support zurücksetzen, aber das dauert.)

Dann die Datei `android/key.properties` anlegen (liegt in .gitignore, landet also nie auf GitHub):

```properties
storeFile=/Users/rb/pixiepaint-upload.jks
storePassword=DEIN_PASSWORT
keyAlias=upload
keyPassword=DEIN_PASSWORT
```

## 3. App-Bundle bauen

```bash
flutter build appbundle --release
```

Ergebnis: `build/app/outputs/bundle/release/app-release.aab`

Hinweis: Ohne `key.properties` baut der Befehl trotzdem (Debug-Signatur als Fallback) – so eine .aab akzeptiert der Play Store aber **nicht**. Für Uploads muss `key.properties` existieren.

## 4. Datenschutzerklärung veröffentlichen

Play verlangt eine öffentliche Datenschutz-URL (besonders für Kinder-Apps):

1. 👤 GitHub-Repo → Settings → Pages → Branch `main`, Ordner `/docs` → Save
2. Die URL ist dann: `https://rbatmaz69.github.io/PixiePaint/privacy-policy`
3. Diese URL später in der Play Console unter „Datenschutzerklärung" eintragen

## 5. 👤 App in der Play Console anlegen

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
> • 22 Ausmalbilder: Tiere, Fahrzeuge, Fantasie und mehr
> • Flächen füllen per Fingertipp oder frei drübermalen
> • Freies Zeichnen auf leerer Leinwand
> • Eigene Fotos anmalen
> • Tolle Stifte: Pinsel, Filzstift, Buntstift, Regenbogen, Glitzer, Neon
> • 20 lustige Sticker-Stempel
> • Zwei-Finger-Zoom für feine Details
> • Stift-Unterstützung mit Druckstärke (S Pen & Co.)
> • Galerie: Bilder speichern, weitermalen und teilen
>
> 👨‍👩‍👧 Für Eltern:
> • Komplett offline – keine Internetverbindung, keine Berechtigungen
> • Keine Werbung, keine In-App-Käufe, keine Datensammlung
> • Teilen, Einstellungen und Löschen hinter einer Elternschranke
> • Automatisches Speichern – kein Bild geht verloren

- **Kategorie:** Lernen (oder Kunst & Design)
- **Grafiken:** App-Icon 512×512 (aus `assets/icon/icon.png` herunterskalieren), Feature-Grafik 1024×500 (kann ich bei Bedarf erstellen), Screenshots: mind. 2 Handy-Screenshots (👤 beim Testen aufnehmen; gern auch 7"/10"-Tablet quer)

## 6. 👤 Formulare in der Play Console

- **Datenschutzerklärung:** URL aus Schritt 4
- **App-Inhalte → Zielgruppe:** „Für Familien entwickelt", Zielgruppe inkl. unter 13. Fragen wahrheitsgemäß: keine Werbung, keine Käufe, keine Datenerhebung, kein soziales Element
- **Datensicherheit-Formular:** „Es werden keine Nutzerdaten erhoben" und „keine Daten weitergegeben" (stimmt: alles bleibt auf dem Gerät; Fotos werden nur lokal verarbeitet)
- **Content-Rating-Fragebogen:** keine Gewalt, keine Sexualität, keine Schimpfwörter, keine Drogen, keine Nutzerinteraktion, keine Standortweitergabe → erwartetes Ergebnis: USK 0 / PEGI 3
- **Werbe-ID:** Nein, App verwendet keine Werbe-ID

## 7. 👤 Hochladen & veröffentlichen

1. Produktion → oder besser zuerst „Interner Test" → Neuer Release
2. `app-release.aab` hochladen
3. Release-Notizen: „Erste Veröffentlichung 🎨"
4. Prüfen & veröffentlichen. Die Google-Prüfung dauert bei Kinder-Apps meist einige Tage

## Checkliste vor dem Upload

- [ ] `key.properties` vorhanden, Keystore gesichert
- [ ] `flutter build appbundle --release` erfolgreich
- [ ] GitHub Pages aktiv, Datenschutz-URL erreichbar
- [ ] Screenshots aufgenommen
- [ ] App auf echtem Gerät getestet (bes. Foto-Modus & Teilen)

## Technische Fakten (für die Formulare)

| | |
|---|---|
| applicationId | `dev.rb.pixiepaint` |
| Version | 3.0.0 (versionCode 3) |
| minSdk | 24 (Android 7.0) |
| Berechtigungen | keine |
| Internet | nein |
| Werbung/Tracking | nein |
