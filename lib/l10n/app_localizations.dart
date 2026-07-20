import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

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

  /// No description provided for @settingsTooltip.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen (für Eltern)'**
  String get settingsTooltip;

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

  /// No description provided for @settingsSectionAbout.
  ///
  /// In de, this message translates to:
  /// **'Info'**
  String get settingsSectionAbout;

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

  /// No description provided for @rewardProgress.
  ///
  /// In de, this message translates to:
  /// **'{done} von {target}'**
  String rewardProgress(int done, int target);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

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
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
