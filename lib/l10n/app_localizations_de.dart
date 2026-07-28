// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'PixiePaint';

  @override
  String get cardColoring => 'Ausmalen';

  @override
  String get cardFreeDraw => 'Frei malen';

  @override
  String get cardPhoto => 'Foto anmalen';

  @override
  String get cardGallery => 'Meine Bilder';

  @override
  String get cardTrace => 'Nachspuren';

  @override
  String get cardScenes => 'Sticker-Welt';

  @override
  String get cardTwoPainter => 'Zu zweit malen';

  @override
  String get twoPainterFlip => 'Seite drehen';

  @override
  String get dailyTaskTitle => 'Aufgabe des Tages';

  @override
  String get dailyTaskGo => 'Los geht\'s!';

  @override
  String get dailyTaskDone => 'Geschafft!';

  @override
  String get dailyTaskAlreadyDone =>
      'Heute schon geschafft – super gemacht! 🎉';

  @override
  String get scenePickerTitle => 'Such dir eine Bühne aus!';

  @override
  String get traceTitle => 'Such dir eine Vorlage aus!';

  @override
  String get traceTabLetters => 'ABC';

  @override
  String get traceTabNumbers => '123';

  @override
  String get traceTabShapes => 'Formen';

  @override
  String get settingsTooltip => 'Einstellungen (für Eltern)';

  @override
  String get profileTitle => 'Wer malt?';

  @override
  String get profileDefaultName => 'Ich';

  @override
  String get profileManage => 'Verwalten (für Eltern)';

  @override
  String get profileAdd => 'Kind hinzufügen';

  @override
  String get profileNameHint => 'Name';

  @override
  String get profilePrimaryBadge => 'Haupt-Profil';

  @override
  String profileRemoveTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get profileRemoveBody =>
      'Was soll mit den Bildern von diesem Kind passieren?';

  @override
  String profileRemoveCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Dieses Kind hat $n Bilder gemalt. Was soll damit passieren?',
      one: 'Dieses Kind hat ein Bild gemalt. Was soll damit passieren?',
      zero: 'Dieses Kind hat noch keine Bilder gemalt. Was soll passieren?',
    );
    return '$_temp0';
  }

  @override
  String profileRemoveConfirmDelete(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Diese $n Bilder wirklich löschen?',
      one: 'Dieses eine Bild wirklich löschen?',
    );
    return '$_temp0';
  }

  @override
  String get profileRemoveDeleteBody => 'Sie sind dann für immer weg.';

  @override
  String get profileRemoveKeepArt => 'Bilder behalten';

  @override
  String get profileRemoveDeleteArt => 'Bilder auch löschen';

  @override
  String get photoDialogTitle => 'Was machen wir mit dem Foto?';

  @override
  String get photoModePaint => 'Foto anmalen';

  @override
  String get photoModeLineArt => 'Ausmalbild zaubern';

  @override
  String get lineArtTitle => 'Ausmalbild zaubern';

  @override
  String get detailFew => 'Wenig Details';

  @override
  String get detailMedium => 'Mittel';

  @override
  String get detailMany => 'Viele Details';

  @override
  String get letsGo => 'Los geht\'s!';

  @override
  String get back => 'Zurück';

  @override
  String get shareForParents => 'Teilen (für Eltern)';

  @override
  String get printForParents => 'Drucken (für Eltern)';

  @override
  String get resetView => 'Ansicht zurücksetzen';

  @override
  String get toolBrush => 'Pinsel';

  @override
  String get toolMarker => 'Filzstift';

  @override
  String get toolCrayon => 'Buntstift';

  @override
  String get toolRainbow => 'Regenbogen';

  @override
  String get toolGlitter => 'Glitzer';

  @override
  String get toolNeon => 'Neon';

  @override
  String get toolTrail => 'Herzchen-Spur';

  @override
  String get toolDotted => 'Punkte-Stift';

  @override
  String get toolTwin => 'Doppellinie';

  @override
  String get toolSticker => 'Sticker';

  @override
  String get toolFill => 'Füllen';

  @override
  String get toolEraser => 'Radierer';

  @override
  String get toolEyedropper => 'Pipette';

  @override
  String get toolWand => 'Zauberstab';

  @override
  String get toolShapes => 'Formen';

  @override
  String get toolText => 'Buchstaben';

  @override
  String get textPickerTitle => 'Was soll auf dem Bild stehen?';

  @override
  String get textPickerHint => 'Dein Name';

  @override
  String get textPickerPlace => 'Aufs Bild setzen';

  @override
  String get shapeCircle => 'Kreis';

  @override
  String get shapeSquare => 'Quadrat';

  @override
  String get shapeHeart => 'Herz';

  @override
  String get shapeStar => 'Stern';

  @override
  String get shapeRainbow => 'Regenbogen';

  @override
  String get shapeLine => 'Linie';

  @override
  String get shapeTriangle => 'Dreieck';

  @override
  String get shapeOval => 'Ei';

  @override
  String get shapeFilled => 'Ausgemalt';

  @override
  String get shapeOutline => 'Nur Rand';

  @override
  String get symmetryTitle => 'Zauber-Spiegel';

  @override
  String get symmetryOff => 'Normal';

  @override
  String get symmetryButterfly => 'Schmetterling';

  @override
  String get symmetryFlower => 'Blume';

  @override
  String get symmetrySnowflake => 'Schneeflocke';

  @override
  String get sizeTitle => 'Pinselgröße';

  @override
  String get colorPickerTitle => 'Alle Farben';

  @override
  String get colorRecent => 'Zuletzt benutzt';

  @override
  String get clearTitle => 'Alles wegwischen?';

  @override
  String get clearBody => 'Möchtest du noch einmal von vorne anfangen?';

  @override
  String get clearKeep => 'Weitermalen!';

  @override
  String get clearConfirm => 'Von vorne';

  @override
  String get patternSolid => 'Einfarbig';

  @override
  String get patternDots => 'Punkte';

  @override
  String get patternStripes => 'Streifen';

  @override
  String get patternRainbow => 'Regenbogen';

  @override
  String get patternHearts => 'Herzen';

  @override
  String get patternStars => 'Sterne';

  @override
  String get patternChecker => 'Karo';

  @override
  String get patternBubbles => 'Seifenblasen';

  @override
  String get galleryTitle => 'Meine Bilder';

  @override
  String get moreForPicture => 'Mehr für dieses Bild';

  @override
  String get galleryEmpty => 'Noch keine Bilder –\nmal doch eins!';

  @override
  String get continuePainting => 'Weitermalen';

  @override
  String get slideshowTooltip => 'Diashow starten';

  @override
  String get replayAction => 'Film anschauen';

  @override
  String get replayAgain => 'Nochmal abspielen';

  @override
  String get replaySpeed => 'Geschwindigkeit';

  @override
  String get renameAction => 'Umbenennen';

  @override
  String get renameTitle => 'Wie heißt dein Bild?';

  @override
  String get renameSave => 'Speichern';

  @override
  String get saveToPhotos => 'In Fotos speichern (für Eltern)';

  @override
  String get savedToPhotos => 'In Fotos gespeichert!';

  @override
  String get saveToPhotosFailedTitle => 'Das hat nicht geklappt';

  @override
  String get saveToPhotosFailed =>
      'Bitte erlaube den Foto-Zugriff in den Geräte-Einstellungen und versuche es noch einmal.';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterFavorites => 'Favoriten';

  @override
  String get okAction => 'Okay!';

  @override
  String get exportWorking => 'Einen Moment …';

  @override
  String get printFailed => 'Das Drucken hat nicht geklappt';

  @override
  String get shareFailed => 'Das Teilen hat nicht geklappt';

  @override
  String get cbnIntroTitle => 'So geht Malen nach Zahlen';

  @override
  String get cbnIntroBody =>
      'Unten siehst du eine Zahl. Suche sie im Bild und tippe hinein – dann wird das Feld bunt.';

  @override
  String get traceIntroTitle => 'So geht Nachspuren';

  @override
  String get traceIntroBody =>
      'Fahre mit dem Finger die Punkte nach. Fang beim grünen Punkt an.';

  @override
  String get deleteAction => 'Wegwerfen';

  @override
  String get deleteTitle => 'Bild wegwerfen?';

  @override
  String get deleteBody => 'Das Bild ist dann für immer weg.';

  @override
  String get deleteKeep => 'Behalten!';

  @override
  String get gateTitle => 'Frag deine Eltern!';

  @override
  String get gateBody =>
      'Dieser Bereich ist für Erwachsene.\nLöse die Aufgabe:';

  @override
  String gateQuestion(int a, int b) {
    return '$a × $b = ?';
  }

  @override
  String get gateHint => 'Antwort';

  @override
  String get gateWrong => 'Leider falsch, versuch es noch einmal.';

  @override
  String get gateGaveUpTitle => 'Das war nicht richtig';

  @override
  String get gateGaveUp =>
      'Frag noch einmal ein Erwachsener — du kannst es gleich wieder versuchen.';

  @override
  String get gateCancel => 'Abbrechen';

  @override
  String get gateContinue => 'Weiter';

  @override
  String get pickerTitle => 'Such dir ein Bild aus!';

  @override
  String get pageAlreadyPainted => 'Schon gemalt';

  @override
  String get pageColorByNumber => 'Malen nach Zahlen';

  @override
  String get categoryAll => 'Alle';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get stylusOnlyTitle => 'Nur mit Stift malen';

  @override
  String get stylusOnlySubtitle =>
      'Fingerberührungen malen nicht – praktisch, damit die Handfläche keine Striche macht.';

  @override
  String get deleteGateTitle => 'Löschen nur für Eltern';

  @override
  String get deleteGateSubtitle =>
      'Bilder können nur nach der Eltern-Frage gelöscht werden.';

  @override
  String get leftHandedTitle => 'Linkshänder-Modus';

  @override
  String get leftHandedSubtitle =>
      'Werkzeuge wandern auf die rechte Seite, damit die malende Hand sie nicht verdeckt.';

  @override
  String get magnifierTitle => 'Lupe beim Malen';

  @override
  String get magnifierSubtitle =>
      'Zeigt vergrößert, was gerade unter dem Finger liegt.';

  @override
  String get soundsTitle => 'Mal-Geräusche';

  @override
  String get soundsSubtitle => 'Leise Töne beim Malen und Stempeln';

  @override
  String get musicTitle => 'Hintergrund-Musik';

  @override
  String get musicSubtitle => 'Sanfte Spieluhr-Musik beim Malen.';

  @override
  String get themeTitle => 'Aussehen';

  @override
  String get themeSubtitle => 'Hell, dunkel oder wie das Gerät';

  @override
  String get themeDuskSubtitle =>
      'Am Abend wird der Hintergrund dunkler – Papier und Bilder bleiben hell';

  @override
  String get themeSystem => 'Wie das Gerät';

  @override
  String get themeLight => 'Immer hell';

  @override
  String get themeDusk => 'Abendmodus';

  @override
  String get aboutTitle => 'PixiePaint';

  @override
  String get aboutBody =>
      'Eine Malbuch-App für Kinder. Keine Werbung, keine Datensammlung – alle Bilder bleiben auf diesem Gerät.';

  @override
  String get welcomeAgainTitle => 'Begrüßung noch einmal';

  @override
  String get welcomeAgainSubtitle => 'Die drei Karten vom ersten Start ansehen';

  @override
  String get rateApp => 'App bewerten';

  @override
  String get rateAppSubtitle => 'Öffnet den Play Store.';

  @override
  String get canvasLoading => 'Dein Bild kommt…';

  @override
  String get galleryEmptyCta => 'Such dir ein Bild aus!';

  @override
  String get settingsSectionSafety => 'Sicherheit';

  @override
  String get settingsSectionFun => 'Spaß';

  @override
  String get settingsSectionParents => 'Für Eltern';

  @override
  String get settingsSectionAbout => 'Info';

  @override
  String get backupTitle => 'Alle Bilder sichern';

  @override
  String get backupSubtitle =>
      'Packt alle Bilder in eine ZIP-Datei zum Teilen oder Aufbewahren.';

  @override
  String get backupWorking => 'Bilder werden gepackt…';

  @override
  String get backupFailed => 'Das Sichern hat leider nicht geklappt.';

  @override
  String get rewardUnlockedTitle => 'Neuer Sticker!';

  @override
  String get rewardUnlockedBody => 'Du hast einen neuen Sticker freigemalt!';

  @override
  String get rewardUnlockedOk => 'Super!';

  @override
  String get rewardLockedTitle => 'Noch geheim!';

  @override
  String get packBasics => 'Lieblinge';

  @override
  String get packAnimals => 'Tiere';

  @override
  String get packSpace => 'Weltraum';

  @override
  String get packFood => 'Leckereien';

  @override
  String get packVehicles => 'Fahrzeuge';

  @override
  String get packRewards => 'Belohnungs-Sticker';

  @override
  String rewardRulePaintings(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Male noch $n Bilder fertig!',
      one: 'Male noch 1 Bild fertig!',
    );
    return '$_temp0';
  }

  @override
  String rewardRuleTools(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Probiere noch $n andere Werkzeuge aus!',
      one: 'Probiere noch 1 anderes Werkzeug aus!',
    );
    return '$_temp0';
  }

  @override
  String get rewardRuleShares => 'Teile ein Bild mit deinen Eltern!';

  @override
  String rewardRuleTrace(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Spure noch $n Vorlagen nach!',
      one: 'Spure noch 1 Vorlage nach!',
    );
    return '$_temp0';
  }

  @override
  String get packMusic => 'Musik';

  @override
  String get packParty => 'Party';

  @override
  String rewardRuleCbn(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Löse noch $n Zahlenbilder!',
      one: 'Löse noch 1 Zahlenbild!',
    );
    return '$_temp0';
  }

  @override
  String rewardRuleTasks(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Schaffe noch $n Tagesaufgaben!',
      one: 'Schaffe noch 1 Tagesaufgabe!',
    );
    return '$_temp0';
  }

  @override
  String get myStickersSection => 'Meine Sticker';

  @override
  String get stickerCaptureTitle => 'Such dir einen Ausschnitt aus!';

  @override
  String get stickerEmptyTitle => 'Erst malen!';

  @override
  String get stickerEmptyBody =>
      'Mal zuerst etwas Schönes – dann kannst du daraus einen Sticker basteln!';

  @override
  String get stickerAlbumFullTitle => 'Sticker-Album voll!';

  @override
  String get stickerAlbumFullBody =>
      'Wirf zuerst einen alten Sticker weg – halte ihn dafür gedrückt.';

  @override
  String get stickerDeleteTitle => 'Sticker wegwerfen?';

  @override
  String get pauseTitle => 'Zeit für eine Pause!';

  @override
  String get pauseBody =>
      'Du malst schon eine ganze Weile. Streck dich, trink etwas – dein Bild wartet auf dich.';

  @override
  String get pauseContinue => 'Weitermalen';

  @override
  String get pauseSaved => 'Dein Bild ist gespeichert.';

  @override
  String get pauseSettingTitle => 'Malzeit-Pause';

  @override
  String get pauseSettingSubtitle =>
      'Nach einer Weile einen freundlichen Pausen-Hinweis zeigen';

  @override
  String get pauseOff => 'Aus';

  @override
  String pauseMinutes(int n) {
    return '$n Minuten';
  }

  @override
  String get albumTitle => 'Meine Erfolge';

  @override
  String get albumStickers => 'Belohnungs-Sticker';

  @override
  String albumEarned(int earned, int total) {
    return '$earned von $total Stickern';
  }

  @override
  String albumStreak(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Tage hintereinander gemalt',
      one: '1 Tag hintereinander gemalt',
    );
    return '$_temp0';
  }

  @override
  String get albumStreakNone =>
      'Schaff die Aufgabe des Tages und starte deine Serie!';

  @override
  String get albumStickerEarned => 'Freigemalt!';

  @override
  String get albumStickerEarnedBody =>
      'Diesen Sticker hast du dir verdient. Du findest ihn beim Stempeln.';

  @override
  String get canvasArea => 'Malfläche';

  @override
  String get undoAction => 'Rückgängig';

  @override
  String get redoAction => 'Wiederholen';

  @override
  String get clearAction => 'Alles wegwischen';

  @override
  String get colorRed => 'Rot';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorYellow => 'Gelb';

  @override
  String get colorLightGreen => 'Hellgrün';

  @override
  String get colorGreen => 'Grün';

  @override
  String get colorTurquoise => 'Türkis';

  @override
  String get colorLightBlue => 'Hellblau';

  @override
  String get colorBlue => 'Blau';

  @override
  String get colorPurple => 'Lila';

  @override
  String get colorPink => 'Pink';

  @override
  String get colorRose => 'Rosa';

  @override
  String get colorBrown => 'Braun';

  @override
  String get colorSkin => 'Hautfarbe';

  @override
  String get colorGrey => 'Grau';

  @override
  String get colorBlack => 'Schwarz';

  @override
  String get colorWhite => 'Weiß';

  @override
  String get colorCustom => 'Eigene Farbe';

  @override
  String get colorMore => 'Mehr Farben';

  @override
  String get storageTitle => 'Speicherplatz';

  @override
  String get storageSubtitle =>
      'Sehen, wie viel Platz PixiePaint braucht – und aufräumen';

  @override
  String storageBreakdown(int count, String art, String stickers) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder · $art',
      one: '1 Bild · $art',
      zero: 'Noch keine Bilder',
    );
    return '$_temp0 · Sticker $stickers';
  }

  @override
  String get storageCleanupHint =>
      'Älteste zuerst. Tippe die Bilder an, die weg dürfen.';

  @override
  String get storageEmpty => 'Hier ist noch nichts gemalt worden.';

  @override
  String get storagePictureFallback => 'Bild';

  @override
  String storageDeleteSelected(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Bilder löschen',
      one: '1 Bild löschen',
    );
    return '$_temp0';
  }

  @override
  String storageDeleteConfirm(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Diese $n Bilder wirklich löschen?',
      one: 'Dieses Bild wirklich löschen?',
    );
    return '$_temp0';
  }

  @override
  String get storageDeleteKeep => 'Doch behalten';

  @override
  String get storageDeleteGo => 'Löschen';

  @override
  String get restoreTitle => 'Bilder zurückholen';

  @override
  String get restoreSubtitle =>
      'Eine Sicherungs-Datei einlesen – vorhandene Bilder bleiben unangetastet';

  @override
  String get restoreWorking => 'Bilder werden zurückgeholt …';

  @override
  String restoreDone(int restored, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      restored,
      locale: localeName,
      other: '$restored Bilder zurückgeholt',
      one: '1 Bild zurückgeholt',
      zero: 'Keine neuen Bilder gefunden',
    );
    String _temp1 = intl.Intl.pluralLogic(
      skipped,
      locale: localeName,
      other: ' – $skipped waren schon da',
      one: ' – 1 war schon da',
      zero: '',
    );
    return '$_temp0$_temp1';
  }

  @override
  String get restoreNotABackup => 'Das ist keine PixiePaint-Sicherung';

  @override
  String get restoreTooNew =>
      'Diese Sicherung stammt aus einer neueren PixiePaint-Version';

  @override
  String get restoreTooLarge => 'Diese Datei ist zu groß zum Einlesen';

  @override
  String get restoreFailed => 'Das Zurückholen hat nicht geklappt';

  @override
  String get saveFailedTitle => 'Das Bild konnte nicht gespeichert werden';

  @override
  String get saveFailedBody =>
      'Wahrscheinlich ist der Speicher voll. Schaffe etwas Platz und versuche es noch einmal – sonst geht dieses Bild verloren.';

  @override
  String get saveFailedRetry => 'Nochmal versuchen';

  @override
  String get saveFailedLeave => 'Trotzdem verlassen';

  @override
  String rewardProgress(int done, int target) {
    return '$done von $target';
  }

  @override
  String get stickerSaveFailed => 'Der Sticker konnte nicht gespeichert werden';

  @override
  String get welcomeSkip => 'Überspringen';

  @override
  String get welcomeNext => 'Weiter';

  @override
  String get welcomeStart => 'Los malen!';

  @override
  String get welcomeHelloTitle => 'Hallo, ich bin Pixie!';

  @override
  String get welcomeHelloBody =>
      'Schön, dass du da bist. Zusammen malen wir die schönsten Bilder.';

  @override
  String get welcomePaintTitle => 'Such dir ein Bild aus';

  @override
  String get welcomePaintBody =>
      'Tippe auf eine Fläche – schon ist sie bunt. Oder male einfach frei drauflos.';

  @override
  String get welcomeParentsTitle => 'Für Eltern';

  @override
  String get welcomeParentsBody =>
      'Alles bleibt auf diesem Gerät: keine Werbung, keine Käufe, keine Datensammlung. Teilen, Löschen und die Einstellungen liegen hinter einer Rechenaufgabe.';

  @override
  String get oopsTitle => 'Ups – hier ist etwas durcheinandergeraten.';

  @override
  String get oopsBody => 'Geh einen Schritt zurück und probier es nochmal.';

  @override
  String get errorLogTitle => 'Problembericht';

  @override
  String get errorLogSubtitle => 'Was zuletzt schiefgegangen ist.';

  @override
  String get errorLogEmpty => 'Alles in Ordnung – nichts zu berichten.';

  @override
  String get errorLogHint =>
      'Diese Liste bleibt auf dem Gerät. Sie enthält Zeitpunkte und technische Meldungen – keine Bilder, keine Namen.';

  @override
  String errorLogCount(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n Einträge',
      one: '1 Eintrag',
      zero: 'Keine Einträge',
    );
    return '$_temp0';
  }

  @override
  String errorLogRepeat(int n) {
    return '$n×';
  }

  @override
  String get errorLogShare => 'Bericht teilen';

  @override
  String get errorLogClear => 'Liste leeren';

  @override
  String get errorLogClearConfirm => 'Alle Einträge löschen?';

  @override
  String get errorLogShareNote =>
      'Aufzeichnung aus PixiePaint – bleibt auf dem Gerät, bis sie bewusst geteilt wird.';

  @override
  String get rotateHint => 'Quer hast du mehr Platz zum Malen';

  @override
  String get simpleToolsTitle => 'Einfache Werkzeuge';

  @override
  String get simpleToolsSubtitle =>
      'Nur Pinsel, Füllen, Sticker und Radierer – für die Kleinsten';

  @override
  String simpleToolsForChild(String name) {
    return 'Nur Pinsel, Füllen, Sticker und Radierer – gilt für $name';
  }

  @override
  String get favoritePageAction => 'Lieblingsbild';

  @override
  String get hapticsTitle => 'Vibrieren';

  @override
  String get hapticsSubtitle => 'Die Knöpfe geben ein kleines Fühl-Signal';
}
