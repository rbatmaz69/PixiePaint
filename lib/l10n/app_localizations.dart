import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'PixiePaint'**
  String get appTitle;

  /// No description provided for @cardColoring.
  ///
  /// In de, this message translates to:
  /// **'Ausmalen'**
  String get cardColoring;

  /// No description provided for @cardFreeDraw.
  ///
  /// In de, this message translates to:
  /// **'Frei malen'**
  String get cardFreeDraw;

  /// No description provided for @cardPhoto.
  ///
  /// In de, this message translates to:
  /// **'Foto anmalen'**
  String get cardPhoto;

  /// No description provided for @cardGallery.
  ///
  /// In de, this message translates to:
  /// **'Meine Bilder'**
  String get cardGallery;

  /// No description provided for @cardTrace.
  ///
  /// In de, this message translates to:
  /// **'Nachspuren'**
  String get cardTrace;

  /// No description provided for @cardScenes.
  ///
  /// In de, this message translates to:
  /// **'Sticker-Welt'**
  String get cardScenes;

  /// No description provided for @cardTwoPainter.
  ///
  /// In de, this message translates to:
  /// **'Zu zweit malen'**
  String get cardTwoPainter;

  /// No description provided for @twoPainterFlip.
  ///
  /// In de, this message translates to:
  /// **'Seite drehen'**
  String get twoPainterFlip;

  /// No description provided for @dailyTaskTitle.
  ///
  /// In de, this message translates to:
  /// **'Aufgabe des Tages'**
  String get dailyTaskTitle;

  /// No description provided for @dailyTaskGo.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s!'**
  String get dailyTaskGo;

  /// No description provided for @dailyTaskDone.
  ///
  /// In de, this message translates to:
  /// **'Geschafft!'**
  String get dailyTaskDone;

  /// No description provided for @dailyTaskAlreadyDone.
  ///
  /// In de, this message translates to:
  /// **'Heute schon geschafft – super gemacht! 🎉'**
  String get dailyTaskAlreadyDone;

  /// No description provided for @scenePickerTitle.
  ///
  /// In de, this message translates to:
  /// **'Such dir eine Bühne aus!'**
  String get scenePickerTitle;

  /// No description provided for @traceTitle.
  ///
  /// In de, this message translates to:
  /// **'Such dir eine Vorlage aus!'**
  String get traceTitle;

  /// No description provided for @traceTabLetters.
  ///
  /// In de, this message translates to:
  /// **'ABC'**
  String get traceTabLetters;

  /// No description provided for @traceTabNumbers.
  ///
  /// In de, this message translates to:
  /// **'123'**
  String get traceTabNumbers;

  /// No description provided for @traceTabShapes.
  ///
  /// In de, this message translates to:
  /// **'Formen'**
  String get traceTabShapes;

  /// No description provided for @settingsTooltip.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen (für Eltern)'**
  String get settingsTooltip;

  /// No description provided for @profileTitle.
  ///
  /// In de, this message translates to:
  /// **'Wer malt?'**
  String get profileTitle;

  /// No description provided for @profileDefaultName.
  ///
  /// In de, this message translates to:
  /// **'Ich'**
  String get profileDefaultName;

  /// No description provided for @profileManage.
  ///
  /// In de, this message translates to:
  /// **'Verwalten (für Eltern)'**
  String get profileManage;

  /// No description provided for @profileAdd.
  ///
  /// In de, this message translates to:
  /// **'Kind hinzufügen'**
  String get profileAdd;

  /// No description provided for @profileNameHint.
  ///
  /// In de, this message translates to:
  /// **'Name'**
  String get profileNameHint;

  /// No description provided for @profilePrimaryBadge.
  ///
  /// In de, this message translates to:
  /// **'Haupt-Profil'**
  String get profilePrimaryBadge;

  /// No description provided for @profileRemoveTitle.
  ///
  /// In de, this message translates to:
  /// **'{name} entfernen?'**
  String profileRemoveTitle(String name);

  /// No description provided for @profileRemoveBody.
  ///
  /// In de, this message translates to:
  /// **'Was soll mit den Bildern von diesem Kind passieren?'**
  String get profileRemoveBody;

  /// No description provided for @profileRemoveKeepArt.
  ///
  /// In de, this message translates to:
  /// **'Bilder behalten'**
  String get profileRemoveKeepArt;

  /// No description provided for @profileRemoveDeleteArt.
  ///
  /// In de, this message translates to:
  /// **'Bilder auch löschen'**
  String get profileRemoveDeleteArt;

  /// No description provided for @photoDialogTitle.
  ///
  /// In de, this message translates to:
  /// **'Was machen wir mit dem Foto?'**
  String get photoDialogTitle;

  /// No description provided for @photoModePaint.
  ///
  /// In de, this message translates to:
  /// **'Foto anmalen'**
  String get photoModePaint;

  /// No description provided for @photoModeLineArt.
  ///
  /// In de, this message translates to:
  /// **'Ausmalbild zaubern'**
  String get photoModeLineArt;

  /// No description provided for @lineArtTitle.
  ///
  /// In de, this message translates to:
  /// **'Ausmalbild zaubern'**
  String get lineArtTitle;

  /// No description provided for @detailFew.
  ///
  /// In de, this message translates to:
  /// **'Wenig Details'**
  String get detailFew;

  /// No description provided for @detailMedium.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get detailMedium;

  /// No description provided for @detailMany.
  ///
  /// In de, this message translates to:
  /// **'Viele Details'**
  String get detailMany;

  /// No description provided for @letsGo.
  ///
  /// In de, this message translates to:
  /// **'Los geht\'s!'**
  String get letsGo;

  /// No description provided for @back.
  ///
  /// In de, this message translates to:
  /// **'Zurück'**
  String get back;

  /// No description provided for @shareForParents.
  ///
  /// In de, this message translates to:
  /// **'Teilen (für Eltern)'**
  String get shareForParents;

  /// No description provided for @printForParents.
  ///
  /// In de, this message translates to:
  /// **'Drucken (für Eltern)'**
  String get printForParents;

  /// No description provided for @resetView.
  ///
  /// In de, this message translates to:
  /// **'Ansicht zurücksetzen'**
  String get resetView;

  /// No description provided for @toolBrush.
  ///
  /// In de, this message translates to:
  /// **'Pinsel'**
  String get toolBrush;

  /// No description provided for @toolMarker.
  ///
  /// In de, this message translates to:
  /// **'Filzstift'**
  String get toolMarker;

  /// No description provided for @toolCrayon.
  ///
  /// In de, this message translates to:
  /// **'Buntstift'**
  String get toolCrayon;

  /// No description provided for @toolRainbow.
  ///
  /// In de, this message translates to:
  /// **'Regenbogen'**
  String get toolRainbow;

  /// No description provided for @toolGlitter.
  ///
  /// In de, this message translates to:
  /// **'Glitzer'**
  String get toolGlitter;

  /// No description provided for @toolNeon.
  ///
  /// In de, this message translates to:
  /// **'Neon'**
  String get toolNeon;

  /// No description provided for @toolTrail.
  ///
  /// In de, this message translates to:
  /// **'Herzchen-Spur'**
  String get toolTrail;

  /// No description provided for @toolDotted.
  ///
  /// In de, this message translates to:
  /// **'Punkte-Stift'**
  String get toolDotted;

  /// No description provided for @toolTwin.
  ///
  /// In de, this message translates to:
  /// **'Doppellinie'**
  String get toolTwin;

  /// No description provided for @toolSticker.
  ///
  /// In de, this message translates to:
  /// **'Sticker'**
  String get toolSticker;

  /// No description provided for @toolFill.
  ///
  /// In de, this message translates to:
  /// **'Füllen'**
  String get toolFill;

  /// No description provided for @toolEraser.
  ///
  /// In de, this message translates to:
  /// **'Radierer'**
  String get toolEraser;

  /// No description provided for @toolEyedropper.
  ///
  /// In de, this message translates to:
  /// **'Pipette'**
  String get toolEyedropper;

  /// No description provided for @toolShapes.
  ///
  /// In de, this message translates to:
  /// **'Formen'**
  String get toolShapes;

  /// No description provided for @shapeCircle.
  ///
  /// In de, this message translates to:
  /// **'Kreis'**
  String get shapeCircle;

  /// No description provided for @shapeSquare.
  ///
  /// In de, this message translates to:
  /// **'Quadrat'**
  String get shapeSquare;

  /// No description provided for @shapeHeart.
  ///
  /// In de, this message translates to:
  /// **'Herz'**
  String get shapeHeart;

  /// No description provided for @shapeStar.
  ///
  /// In de, this message translates to:
  /// **'Stern'**
  String get shapeStar;

  /// No description provided for @shapeRainbow.
  ///
  /// In de, this message translates to:
  /// **'Regenbogen'**
  String get shapeRainbow;

  /// No description provided for @symmetryTitle.
  ///
  /// In de, this message translates to:
  /// **'Zauber-Spiegel'**
  String get symmetryTitle;

  /// No description provided for @symmetryOff.
  ///
  /// In de, this message translates to:
  /// **'Normal'**
  String get symmetryOff;

  /// No description provided for @symmetryButterfly.
  ///
  /// In de, this message translates to:
  /// **'Schmetterling'**
  String get symmetryButterfly;

  /// No description provided for @symmetryFlower.
  ///
  /// In de, this message translates to:
  /// **'Blume'**
  String get symmetryFlower;

  /// No description provided for @symmetrySnowflake.
  ///
  /// In de, this message translates to:
  /// **'Schneeflocke'**
  String get symmetrySnowflake;

  /// No description provided for @sizeTitle.
  ///
  /// In de, this message translates to:
  /// **'Pinselgröße'**
  String get sizeTitle;

  /// No description provided for @colorPickerTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle Farben'**
  String get colorPickerTitle;

  /// No description provided for @colorRecent.
  ///
  /// In de, this message translates to:
  /// **'Zuletzt benutzt'**
  String get colorRecent;

  /// No description provided for @clearTitle.
  ///
  /// In de, this message translates to:
  /// **'Alles wegwischen?'**
  String get clearTitle;

  /// No description provided for @clearBody.
  ///
  /// In de, this message translates to:
  /// **'Möchtest du noch einmal von vorne anfangen?'**
  String get clearBody;

  /// No description provided for @clearKeep.
  ///
  /// In de, this message translates to:
  /// **'Weitermalen!'**
  String get clearKeep;

  /// No description provided for @clearConfirm.
  ///
  /// In de, this message translates to:
  /// **'Von vorne'**
  String get clearConfirm;

  /// No description provided for @patternSolid.
  ///
  /// In de, this message translates to:
  /// **'Einfarbig'**
  String get patternSolid;

  /// No description provided for @patternDots.
  ///
  /// In de, this message translates to:
  /// **'Punkte'**
  String get patternDots;

  /// No description provided for @patternStripes.
  ///
  /// In de, this message translates to:
  /// **'Streifen'**
  String get patternStripes;

  /// No description provided for @patternRainbow.
  ///
  /// In de, this message translates to:
  /// **'Regenbogen'**
  String get patternRainbow;

  /// No description provided for @patternHearts.
  ///
  /// In de, this message translates to:
  /// **'Herzen'**
  String get patternHearts;

  /// No description provided for @patternStars.
  ///
  /// In de, this message translates to:
  /// **'Sterne'**
  String get patternStars;

  /// No description provided for @patternChecker.
  ///
  /// In de, this message translates to:
  /// **'Karo'**
  String get patternChecker;

  /// No description provided for @patternBubbles.
  ///
  /// In de, this message translates to:
  /// **'Seifenblasen'**
  String get patternBubbles;

  /// No description provided for @galleryTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Bilder'**
  String get galleryTitle;

  /// No description provided for @galleryEmpty.
  ///
  /// In de, this message translates to:
  /// **'Noch keine Bilder –\nmal doch eins!'**
  String get galleryEmpty;

  /// No description provided for @continuePainting.
  ///
  /// In de, this message translates to:
  /// **'Weitermalen'**
  String get continuePainting;

  /// No description provided for @slideshowTooltip.
  ///
  /// In de, this message translates to:
  /// **'Diashow starten'**
  String get slideshowTooltip;

  /// No description provided for @replayAction.
  ///
  /// In de, this message translates to:
  /// **'Film anschauen'**
  String get replayAction;

  /// No description provided for @replayAgain.
  ///
  /// In de, this message translates to:
  /// **'Nochmal abspielen'**
  String get replayAgain;

  /// No description provided for @replaySpeed.
  ///
  /// In de, this message translates to:
  /// **'Geschwindigkeit'**
  String get replaySpeed;

  /// No description provided for @renameAction.
  ///
  /// In de, this message translates to:
  /// **'Umbenennen'**
  String get renameAction;

  /// No description provided for @renameTitle.
  ///
  /// In de, this message translates to:
  /// **'Wie heißt dein Bild?'**
  String get renameTitle;

  /// No description provided for @renameSave.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get renameSave;

  /// No description provided for @saveToPhotos.
  ///
  /// In de, this message translates to:
  /// **'In Fotos speichern (für Eltern)'**
  String get saveToPhotos;

  /// No description provided for @savedToPhotos.
  ///
  /// In de, this message translates to:
  /// **'In Fotos gespeichert!'**
  String get savedToPhotos;

  /// No description provided for @saveToPhotosFailedTitle.
  ///
  /// In de, this message translates to:
  /// **'Das hat nicht geklappt'**
  String get saveToPhotosFailedTitle;

  /// No description provided for @saveToPhotosFailed.
  ///
  /// In de, this message translates to:
  /// **'Bitte erlaube den Foto-Zugriff in den Geräte-Einstellungen und versuche es noch einmal.'**
  String get saveToPhotosFailed;

  /// No description provided for @filterAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get filterAll;

  /// No description provided for @filterFavorites.
  ///
  /// In de, this message translates to:
  /// **'Favoriten'**
  String get filterFavorites;

  /// No description provided for @okAction.
  ///
  /// In de, this message translates to:
  /// **'Okay!'**
  String get okAction;

  /// No description provided for @deleteAction.
  ///
  /// In de, this message translates to:
  /// **'Wegwerfen'**
  String get deleteAction;

  /// No description provided for @deleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Bild wegwerfen?'**
  String get deleteTitle;

  /// No description provided for @deleteBody.
  ///
  /// In de, this message translates to:
  /// **'Das Bild ist dann für immer weg.'**
  String get deleteBody;

  /// No description provided for @deleteKeep.
  ///
  /// In de, this message translates to:
  /// **'Behalten!'**
  String get deleteKeep;

  /// No description provided for @gateTitle.
  ///
  /// In de, this message translates to:
  /// **'Frag deine Eltern!'**
  String get gateTitle;

  /// No description provided for @gateBody.
  ///
  /// In de, this message translates to:
  /// **'Dieser Bereich ist für Erwachsene.\nLöse die Aufgabe:'**
  String get gateBody;

  /// No description provided for @gateQuestion.
  ///
  /// In de, this message translates to:
  /// **'{a} × {b} = ?'**
  String gateQuestion(int a, int b);

  /// No description provided for @gateHint.
  ///
  /// In de, this message translates to:
  /// **'Antwort'**
  String get gateHint;

  /// No description provided for @gateWrong.
  ///
  /// In de, this message translates to:
  /// **'Leider falsch, versuch es noch einmal.'**
  String get gateWrong;

  /// No description provided for @gateCancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get gateCancel;

  /// No description provided for @gateContinue.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get gateContinue;

  /// No description provided for @pickerTitle.
  ///
  /// In de, this message translates to:
  /// **'Such dir ein Bild aus!'**
  String get pickerTitle;

  /// No description provided for @categoryAll.
  ///
  /// In de, this message translates to:
  /// **'Alle'**
  String get categoryAll;

  /// No description provided for @settingsTitle.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settingsTitle;

  /// No description provided for @stylusOnlyTitle.
  ///
  /// In de, this message translates to:
  /// **'Nur mit Stift malen'**
  String get stylusOnlyTitle;

  /// No description provided for @stylusOnlySubtitle.
  ///
  /// In de, this message translates to:
  /// **'Fingerberührungen malen nicht – praktisch, damit die Handfläche keine Striche macht.'**
  String get stylusOnlySubtitle;

  /// No description provided for @deleteGateTitle.
  ///
  /// In de, this message translates to:
  /// **'Löschen nur für Eltern'**
  String get deleteGateTitle;

  /// No description provided for @deleteGateSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Bilder können nur nach der Eltern-Frage gelöscht werden.'**
  String get deleteGateSubtitle;

  /// No description provided for @leftHandedTitle.
  ///
  /// In de, this message translates to:
  /// **'Linkshänder-Modus'**
  String get leftHandedTitle;

  /// No description provided for @leftHandedSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Werkzeuge wandern auf die rechte Seite, damit die malende Hand sie nicht verdeckt.'**
  String get leftHandedSubtitle;

  /// No description provided for @soundsTitle.
  ///
  /// In de, this message translates to:
  /// **'Töne & Vibration'**
  String get soundsTitle;

  /// No description provided for @soundsSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Leise Geräusche beim Malen und Stempeln.'**
  String get soundsSubtitle;

  /// No description provided for @musicTitle.
  ///
  /// In de, this message translates to:
  /// **'Hintergrund-Musik'**
  String get musicTitle;

  /// No description provided for @musicSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Sanfte Spieluhr-Musik beim Malen.'**
  String get musicSubtitle;

  /// No description provided for @aboutTitle.
  ///
  /// In de, this message translates to:
  /// **'PixiePaint'**
  String get aboutTitle;

  /// No description provided for @aboutBody.
  ///
  /// In de, this message translates to:
  /// **'Eine Malbuch-App für Kinder. Keine Werbung, keine Datensammlung – alle Bilder bleiben auf diesem Gerät.'**
  String get aboutBody;

  /// No description provided for @rateApp.
  ///
  /// In de, this message translates to:
  /// **'App bewerten'**
  String get rateApp;

  /// No description provided for @rateAppSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Öffnet den Play Store.'**
  String get rateAppSubtitle;

  /// No description provided for @canvasLoading.
  ///
  /// In de, this message translates to:
  /// **'Dein Bild kommt…'**
  String get canvasLoading;

  /// No description provided for @galleryEmptyCta.
  ///
  /// In de, this message translates to:
  /// **'Such dir ein Bild aus!'**
  String get galleryEmptyCta;

  /// No description provided for @settingsSectionSafety.
  ///
  /// In de, this message translates to:
  /// **'Sicherheit'**
  String get settingsSectionSafety;

  /// No description provided for @settingsSectionFun.
  ///
  /// In de, this message translates to:
  /// **'Spaß'**
  String get settingsSectionFun;

  /// No description provided for @settingsSectionParents.
  ///
  /// In de, this message translates to:
  /// **'Für Eltern'**
  String get settingsSectionParents;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In de, this message translates to:
  /// **'Info'**
  String get settingsSectionAbout;

  /// No description provided for @backupTitle.
  ///
  /// In de, this message translates to:
  /// **'Alle Bilder sichern'**
  String get backupTitle;

  /// No description provided for @backupSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Packt alle Bilder in eine ZIP-Datei zum Teilen oder Aufbewahren.'**
  String get backupSubtitle;

  /// No description provided for @backupWorking.
  ///
  /// In de, this message translates to:
  /// **'Bilder werden gepackt…'**
  String get backupWorking;

  /// No description provided for @backupFailed.
  ///
  /// In de, this message translates to:
  /// **'Das Sichern hat leider nicht geklappt.'**
  String get backupFailed;

  /// No description provided for @rewardUnlockedTitle.
  ///
  /// In de, this message translates to:
  /// **'Neuer Sticker!'**
  String get rewardUnlockedTitle;

  /// No description provided for @rewardUnlockedBody.
  ///
  /// In de, this message translates to:
  /// **'Du hast einen neuen Sticker freigemalt!'**
  String get rewardUnlockedBody;

  /// No description provided for @rewardUnlockedOk.
  ///
  /// In de, this message translates to:
  /// **'Super!'**
  String get rewardUnlockedOk;

  /// No description provided for @rewardLockedTitle.
  ///
  /// In de, this message translates to:
  /// **'Noch geheim!'**
  String get rewardLockedTitle;

  /// No description provided for @packBasics.
  ///
  /// In de, this message translates to:
  /// **'Lieblinge'**
  String get packBasics;

  /// No description provided for @packAnimals.
  ///
  /// In de, this message translates to:
  /// **'Tiere'**
  String get packAnimals;

  /// No description provided for @packSpace.
  ///
  /// In de, this message translates to:
  /// **'Weltraum'**
  String get packSpace;

  /// No description provided for @packFood.
  ///
  /// In de, this message translates to:
  /// **'Leckereien'**
  String get packFood;

  /// No description provided for @packVehicles.
  ///
  /// In de, this message translates to:
  /// **'Fahrzeuge'**
  String get packVehicles;

  /// No description provided for @packRewards.
  ///
  /// In de, this message translates to:
  /// **'Belohnungs-Sticker'**
  String get packRewards;

  /// No description provided for @rewardRulePaintings.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{Male noch 1 Bild fertig!} other{Male noch {n} Bilder fertig!}}'**
  String rewardRulePaintings(int n);

  /// No description provided for @rewardRuleTools.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{Probiere noch 1 anderes Werkzeug aus!} other{Probiere noch {n} andere Werkzeuge aus!}}'**
  String rewardRuleTools(int n);

  /// No description provided for @rewardRuleShares.
  ///
  /// In de, this message translates to:
  /// **'Teile ein Bild mit deinen Eltern!'**
  String get rewardRuleShares;

  /// No description provided for @rewardRuleTrace.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{Spure noch 1 Vorlage nach!} other{Spure noch {n} Vorlagen nach!}}'**
  String rewardRuleTrace(int n);

  /// No description provided for @packMusic.
  ///
  /// In de, this message translates to:
  /// **'Musik'**
  String get packMusic;

  /// No description provided for @packParty.
  ///
  /// In de, this message translates to:
  /// **'Party'**
  String get packParty;

  /// No description provided for @rewardRuleCbn.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{Löse noch 1 Zahlenbild!} other{Löse noch {n} Zahlenbilder!}}'**
  String rewardRuleCbn(int n);

  /// No description provided for @rewardRuleTasks.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{Schaffe noch 1 Tagesaufgabe!} other{Schaffe noch {n} Tagesaufgaben!}}'**
  String rewardRuleTasks(int n);

  /// No description provided for @myStickersSection.
  ///
  /// In de, this message translates to:
  /// **'Meine Sticker'**
  String get myStickersSection;

  /// No description provided for @stickerCaptureTitle.
  ///
  /// In de, this message translates to:
  /// **'Such dir einen Ausschnitt aus!'**
  String get stickerCaptureTitle;

  /// No description provided for @stickerEmptyTitle.
  ///
  /// In de, this message translates to:
  /// **'Erst malen!'**
  String get stickerEmptyTitle;

  /// No description provided for @stickerEmptyBody.
  ///
  /// In de, this message translates to:
  /// **'Mal zuerst etwas Schönes – dann kannst du daraus einen Sticker basteln!'**
  String get stickerEmptyBody;

  /// No description provided for @stickerAlbumFullTitle.
  ///
  /// In de, this message translates to:
  /// **'Sticker-Album voll!'**
  String get stickerAlbumFullTitle;

  /// No description provided for @stickerAlbumFullBody.
  ///
  /// In de, this message translates to:
  /// **'Wirf zuerst einen alten Sticker weg – halte ihn dafür gedrückt.'**
  String get stickerAlbumFullBody;

  /// No description provided for @stickerDeleteTitle.
  ///
  /// In de, this message translates to:
  /// **'Sticker wegwerfen?'**
  String get stickerDeleteTitle;

  /// No description provided for @pauseTitle.
  ///
  /// In de, this message translates to:
  /// **'Zeit für eine Pause!'**
  String get pauseTitle;

  /// No description provided for @pauseBody.
  ///
  /// In de, this message translates to:
  /// **'Du malst schon eine ganze Weile. Streck dich, trink etwas – dein Bild wartet auf dich.'**
  String get pauseBody;

  /// No description provided for @pauseContinue.
  ///
  /// In de, this message translates to:
  /// **'Weitermalen'**
  String get pauseContinue;

  /// No description provided for @pauseSaved.
  ///
  /// In de, this message translates to:
  /// **'Dein Bild ist gespeichert.'**
  String get pauseSaved;

  /// No description provided for @pauseSettingTitle.
  ///
  /// In de, this message translates to:
  /// **'Malzeit-Pause'**
  String get pauseSettingTitle;

  /// No description provided for @pauseSettingSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Nach einer Weile einen freundlichen Pausen-Hinweis zeigen'**
  String get pauseSettingSubtitle;

  /// No description provided for @pauseOff.
  ///
  /// In de, this message translates to:
  /// **'Aus'**
  String get pauseOff;

  /// No description provided for @pauseMinutes.
  ///
  /// In de, this message translates to:
  /// **'{n} Minuten'**
  String pauseMinutes(int n);

  /// No description provided for @albumTitle.
  ///
  /// In de, this message translates to:
  /// **'Meine Erfolge'**
  String get albumTitle;

  /// No description provided for @albumStickers.
  ///
  /// In de, this message translates to:
  /// **'Belohnungs-Sticker'**
  String get albumStickers;

  /// No description provided for @albumEarned.
  ///
  /// In de, this message translates to:
  /// **'{earned} von {total} Stickern'**
  String albumEarned(int earned, int total);

  /// No description provided for @albumStreak.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Tag hintereinander gemalt} other{{n} Tage hintereinander gemalt}}'**
  String albumStreak(int n);

  /// No description provided for @albumStreakNone.
  ///
  /// In de, this message translates to:
  /// **'Schaff die Aufgabe des Tages und starte deine Serie!'**
  String get albumStreakNone;

  /// No description provided for @albumStickerEarned.
  ///
  /// In de, this message translates to:
  /// **'Freigemalt!'**
  String get albumStickerEarned;

  /// No description provided for @albumStickerEarnedBody.
  ///
  /// In de, this message translates to:
  /// **'Diesen Sticker hast du dir verdient. Du findest ihn beim Stempeln.'**
  String get albumStickerEarnedBody;

  /// No description provided for @canvasArea.
  ///
  /// In de, this message translates to:
  /// **'Malfläche'**
  String get canvasArea;

  /// No description provided for @undoAction.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get undoAction;

  /// No description provided for @redoAction.
  ///
  /// In de, this message translates to:
  /// **'Wiederholen'**
  String get redoAction;

  /// No description provided for @clearAction.
  ///
  /// In de, this message translates to:
  /// **'Alles wegwischen'**
  String get clearAction;

  /// No description provided for @colorRed.
  ///
  /// In de, this message translates to:
  /// **'Rot'**
  String get colorRed;

  /// No description provided for @colorOrange.
  ///
  /// In de, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorYellow.
  ///
  /// In de, this message translates to:
  /// **'Gelb'**
  String get colorYellow;

  /// No description provided for @colorLightGreen.
  ///
  /// In de, this message translates to:
  /// **'Hellgrün'**
  String get colorLightGreen;

  /// No description provided for @colorGreen.
  ///
  /// In de, this message translates to:
  /// **'Grün'**
  String get colorGreen;

  /// No description provided for @colorTurquoise.
  ///
  /// In de, this message translates to:
  /// **'Türkis'**
  String get colorTurquoise;

  /// No description provided for @colorLightBlue.
  ///
  /// In de, this message translates to:
  /// **'Hellblau'**
  String get colorLightBlue;

  /// No description provided for @colorBlue.
  ///
  /// In de, this message translates to:
  /// **'Blau'**
  String get colorBlue;

  /// No description provided for @colorPurple.
  ///
  /// In de, this message translates to:
  /// **'Lila'**
  String get colorPurple;

  /// No description provided for @colorPink.
  ///
  /// In de, this message translates to:
  /// **'Pink'**
  String get colorPink;

  /// No description provided for @colorRose.
  ///
  /// In de, this message translates to:
  /// **'Rosa'**
  String get colorRose;

  /// No description provided for @colorBrown.
  ///
  /// In de, this message translates to:
  /// **'Braun'**
  String get colorBrown;

  /// No description provided for @colorSkin.
  ///
  /// In de, this message translates to:
  /// **'Hautfarbe'**
  String get colorSkin;

  /// No description provided for @colorGrey.
  ///
  /// In de, this message translates to:
  /// **'Grau'**
  String get colorGrey;

  /// No description provided for @colorBlack.
  ///
  /// In de, this message translates to:
  /// **'Schwarz'**
  String get colorBlack;

  /// No description provided for @colorWhite.
  ///
  /// In de, this message translates to:
  /// **'Weiß'**
  String get colorWhite;

  /// No description provided for @colorCustom.
  ///
  /// In de, this message translates to:
  /// **'Eigene Farbe'**
  String get colorCustom;

  /// No description provided for @colorMore.
  ///
  /// In de, this message translates to:
  /// **'Mehr Farben'**
  String get colorMore;

  /// No description provided for @storageTitle.
  ///
  /// In de, this message translates to:
  /// **'Speicherplatz'**
  String get storageTitle;

  /// No description provided for @storageSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Sehen, wie viel Platz PixiePaint braucht – und aufräumen'**
  String get storageSubtitle;

  /// No description provided for @storageBreakdown.
  ///
  /// In de, this message translates to:
  /// **'{count, plural, =0{Noch keine Bilder} =1{1 Bild · {art}} other{{count} Bilder · {art}}} · Sticker {stickers}'**
  String storageBreakdown(int count, String art, String stickers);

  /// No description provided for @storageCleanupHint.
  ///
  /// In de, this message translates to:
  /// **'Älteste zuerst. Tippe die Bilder an, die weg dürfen.'**
  String get storageCleanupHint;

  /// No description provided for @storageEmpty.
  ///
  /// In de, this message translates to:
  /// **'Hier ist noch nichts gemalt worden.'**
  String get storageEmpty;

  /// No description provided for @storagePictureFallback.
  ///
  /// In de, this message translates to:
  /// **'Bild'**
  String get storagePictureFallback;

  /// No description provided for @storageDeleteSelected.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{1 Bild löschen} other{{n} Bilder löschen}}'**
  String storageDeleteSelected(int n);

  /// No description provided for @storageDeleteConfirm.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =1{Dieses Bild wirklich löschen?} other{Diese {n} Bilder wirklich löschen?}}'**
  String storageDeleteConfirm(int n);

  /// No description provided for @storageDeleteKeep.
  ///
  /// In de, this message translates to:
  /// **'Doch behalten'**
  String get storageDeleteKeep;

  /// No description provided for @storageDeleteGo.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get storageDeleteGo;

  /// No description provided for @restoreTitle.
  ///
  /// In de, this message translates to:
  /// **'Bilder zurückholen'**
  String get restoreTitle;

  /// No description provided for @restoreSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Eine Sicherungs-Datei einlesen – vorhandene Bilder bleiben unangetastet'**
  String get restoreSubtitle;

  /// No description provided for @restoreWorking.
  ///
  /// In de, this message translates to:
  /// **'Bilder werden zurückgeholt …'**
  String get restoreWorking;

  /// No description provided for @restoreDone.
  ///
  /// In de, this message translates to:
  /// **'{restored, plural, =0{Keine neuen Bilder gefunden} =1{1 Bild zurückgeholt} other{{restored} Bilder zurückgeholt}}{skipped, plural, =0{} =1{ – 1 war schon da} other{ – {skipped} waren schon da}}'**
  String restoreDone(int restored, int skipped);

  /// No description provided for @restoreNotABackup.
  ///
  /// In de, this message translates to:
  /// **'Das ist keine PixiePaint-Sicherung'**
  String get restoreNotABackup;

  /// No description provided for @restoreTooNew.
  ///
  /// In de, this message translates to:
  /// **'Diese Sicherung stammt aus einer neueren PixiePaint-Version'**
  String get restoreTooNew;

  /// No description provided for @restoreTooLarge.
  ///
  /// In de, this message translates to:
  /// **'Diese Datei ist zu groß zum Einlesen'**
  String get restoreTooLarge;

  /// No description provided for @restoreFailed.
  ///
  /// In de, this message translates to:
  /// **'Das Zurückholen hat nicht geklappt'**
  String get restoreFailed;

  /// No description provided for @saveFailedTitle.
  ///
  /// In de, this message translates to:
  /// **'Das Bild konnte nicht gespeichert werden'**
  String get saveFailedTitle;

  /// No description provided for @saveFailedBody.
  ///
  /// In de, this message translates to:
  /// **'Wahrscheinlich ist der Speicher voll. Schaffe etwas Platz und versuche es noch einmal – sonst geht dieses Bild verloren.'**
  String get saveFailedBody;

  /// No description provided for @saveFailedRetry.
  ///
  /// In de, this message translates to:
  /// **'Nochmal versuchen'**
  String get saveFailedRetry;

  /// No description provided for @saveFailedLeave.
  ///
  /// In de, this message translates to:
  /// **'Trotzdem verlassen'**
  String get saveFailedLeave;

  /// No description provided for @rewardProgress.
  ///
  /// In de, this message translates to:
  /// **'{done} von {target}'**
  String rewardProgress(int done, int target);

  /// No description provided for @stickerSaveFailed.
  ///
  /// In de, this message translates to:
  /// **'Der Sticker konnte nicht gespeichert werden'**
  String get stickerSaveFailed;

  /// No description provided for @welcomeSkip.
  ///
  /// In de, this message translates to:
  /// **'Überspringen'**
  String get welcomeSkip;

  /// No description provided for @welcomeNext.
  ///
  /// In de, this message translates to:
  /// **'Weiter'**
  String get welcomeNext;

  /// No description provided for @welcomeStart.
  ///
  /// In de, this message translates to:
  /// **'Los malen!'**
  String get welcomeStart;

  /// No description provided for @welcomeHelloTitle.
  ///
  /// In de, this message translates to:
  /// **'Hallo, ich bin Pixie!'**
  String get welcomeHelloTitle;

  /// No description provided for @welcomeHelloBody.
  ///
  /// In de, this message translates to:
  /// **'Schön, dass du da bist. Zusammen malen wir die schönsten Bilder.'**
  String get welcomeHelloBody;

  /// No description provided for @welcomePaintTitle.
  ///
  /// In de, this message translates to:
  /// **'Such dir ein Bild aus'**
  String get welcomePaintTitle;

  /// No description provided for @welcomePaintBody.
  ///
  /// In de, this message translates to:
  /// **'Tippe auf eine Fläche – schon ist sie bunt. Oder male einfach frei drauflos.'**
  String get welcomePaintBody;

  /// No description provided for @welcomeParentsTitle.
  ///
  /// In de, this message translates to:
  /// **'Für Eltern'**
  String get welcomeParentsTitle;

  /// No description provided for @welcomeParentsBody.
  ///
  /// In de, this message translates to:
  /// **'Alles bleibt auf diesem Gerät: keine Werbung, keine Käufe, keine Datensammlung. Teilen, Löschen und die Einstellungen liegen hinter einer Rechenaufgabe.'**
  String get welcomeParentsBody;

  /// No description provided for @oopsTitle.
  ///
  /// In de, this message translates to:
  /// **'Ups – hier ist etwas durcheinandergeraten.'**
  String get oopsTitle;

  /// No description provided for @oopsBody.
  ///
  /// In de, this message translates to:
  /// **'Geh einen Schritt zurück und probier es nochmal.'**
  String get oopsBody;

  /// No description provided for @errorLogTitle.
  ///
  /// In de, this message translates to:
  /// **'Problembericht'**
  String get errorLogTitle;

  /// No description provided for @errorLogSubtitle.
  ///
  /// In de, this message translates to:
  /// **'Was zuletzt schiefgegangen ist.'**
  String get errorLogSubtitle;

  /// No description provided for @errorLogEmpty.
  ///
  /// In de, this message translates to:
  /// **'Alles in Ordnung – nichts zu berichten.'**
  String get errorLogEmpty;

  /// No description provided for @errorLogHint.
  ///
  /// In de, this message translates to:
  /// **'Diese Liste bleibt auf dem Gerät. Sie enthält Zeitpunkte und technische Meldungen – keine Bilder, keine Namen.'**
  String get errorLogHint;

  /// No description provided for @errorLogCount.
  ///
  /// In de, this message translates to:
  /// **'{n, plural, =0{Keine Einträge} =1{1 Eintrag} other{{n} Einträge}}'**
  String errorLogCount(int n);

  /// No description provided for @errorLogRepeat.
  ///
  /// In de, this message translates to:
  /// **'{n}×'**
  String errorLogRepeat(int n);

  /// No description provided for @errorLogShare.
  ///
  /// In de, this message translates to:
  /// **'Bericht teilen'**
  String get errorLogShare;

  /// No description provided for @errorLogClear.
  ///
  /// In de, this message translates to:
  /// **'Liste leeren'**
  String get errorLogClear;

  /// No description provided for @errorLogClearConfirm.
  ///
  /// In de, this message translates to:
  /// **'Alle Einträge löschen?'**
  String get errorLogClearConfirm;

  /// No description provided for @errorLogShareNote.
  ///
  /// In de, this message translates to:
  /// **'Aufzeichnung aus PixiePaint – bleibt auf dem Gerät, bis sie bewusst geteilt wird.'**
  String get errorLogShareNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'it',
    'nl',
    'pl',
    'pt',
    'tr',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
