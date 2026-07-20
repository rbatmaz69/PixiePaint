// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PixiePaint';

  @override
  String get cardColoring => 'Coloring';

  @override
  String get cardFreeDraw => 'Free drawing';

  @override
  String get cardPhoto => 'Paint a photo';

  @override
  String get cardGallery => 'My pictures';

  @override
  String get settingsTooltip => 'Settings (for parents)';

  @override
  String get photoDialogTitle => 'What shall we do with the photo?';

  @override
  String get photoModePaint => 'Paint on the photo';

  @override
  String get photoModeLineArt => 'Magic coloring page';

  @override
  String get lineArtTitle => 'Magic coloring page';

  @override
  String get detailFew => 'Few details';

  @override
  String get detailMedium => 'Medium';

  @override
  String get detailMany => 'Many details';

  @override
  String get letsGo => 'Let\'s go!';

  @override
  String get back => 'Back';

  @override
  String get shareForParents => 'Share (for parents)';

  @override
  String get resetView => 'Reset view';

  @override
  String get toolBrush => 'Brush';

  @override
  String get toolMarker => 'Marker';

  @override
  String get toolCrayon => 'Crayon';

  @override
  String get toolRainbow => 'Rainbow';

  @override
  String get toolGlitter => 'Glitter';

  @override
  String get toolNeon => 'Neon';

  @override
  String get toolSticker => 'Sticker';

  @override
  String get toolFill => 'Fill';

  @override
  String get toolEraser => 'Eraser';

  @override
  String get toolEyedropper => 'Color picker';

  @override
  String get toolShapes => 'Shapes';

  @override
  String get shapeCircle => 'Circle';

  @override
  String get shapeSquare => 'Square';

  @override
  String get shapeHeart => 'Heart';

  @override
  String get shapeStar => 'Star';

  @override
  String get shapeRainbow => 'Rainbow';

  @override
  String get sizeTitle => 'Brush size';

  @override
  String get colorPickerTitle => 'All colors';

  @override
  String get colorRecent => 'Recently used';

  @override
  String get clearTitle => 'Wipe everything?';

  @override
  String get clearBody => 'Do you want to start over?';

  @override
  String get clearKeep => 'Keep painting!';

  @override
  String get clearConfirm => 'Start over';

  @override
  String get patternSolid => 'Solid';

  @override
  String get patternDots => 'Dots';

  @override
  String get patternStripes => 'Stripes';

  @override
  String get patternRainbow => 'Rainbow';

  @override
  String get galleryTitle => 'My pictures';

  @override
  String get galleryEmpty => 'No pictures yet –\npaint one!';

  @override
  String get continuePainting => 'Keep painting';

  @override
  String get renameAction => 'Rename';

  @override
  String get renameTitle => 'What\'s your picture called?';

  @override
  String get renameSave => 'Save';

  @override
  String get saveToPhotos => 'Save to Photos (for parents)';

  @override
  String get savedToPhotos => 'Saved to Photos!';

  @override
  String get saveToPhotosFailedTitle => 'That didn\'t work';

  @override
  String get saveToPhotosFailed =>
      'Please allow photo access in the device settings and try again.';

  @override
  String get filterAll => 'All';

  @override
  String get filterFavorites => 'Favorites';

  @override
  String get okAction => 'Okay!';

  @override
  String get deleteAction => 'Throw away';

  @override
  String get deleteTitle => 'Throw the picture away?';

  @override
  String get deleteBody => 'The picture will be gone forever.';

  @override
  String get deleteKeep => 'Keep it!';

  @override
  String get gateTitle => 'Ask your parents!';

  @override
  String get gateBody => 'This area is for grown-ups.\nSolve the problem:';

  @override
  String gateQuestion(int a, int b) {
    return '$a × $b = ?';
  }

  @override
  String get gateHint => 'Answer';

  @override
  String get gateWrong => 'Not quite, try again.';

  @override
  String get gateCancel => 'Cancel';

  @override
  String get gateContinue => 'Continue';

  @override
  String get pickerTitle => 'Pick a picture!';

  @override
  String get categoryAll => 'All';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get stylusOnlyTitle => 'Draw with stylus only';

  @override
  String get stylusOnlySubtitle =>
      'Finger touches don\'t draw – handy so resting palms don\'t leave marks.';

  @override
  String get deleteGateTitle => 'Deleting needs a parent';

  @override
  String get deleteGateSubtitle =>
      'Pictures can only be deleted after the parent question.';

  @override
  String get soundsTitle => 'Sounds & vibration';

  @override
  String get soundsSubtitle => 'Soft sounds while painting and stamping.';

  @override
  String get aboutTitle => 'PixiePaint';

  @override
  String get aboutBody =>
      'A coloring book app for kids. No ads, no data collection – all pictures stay on this device.';

  @override
  String get rateApp => 'Rate the app';

  @override
  String get rateAppSubtitle => 'Opens the Play Store.';

  @override
  String get canvasLoading => 'Your picture is coming…';

  @override
  String get galleryEmptyCta => 'Pick a picture!';

  @override
  String get settingsSectionSafety => 'Safety';

  @override
  String get settingsSectionFun => 'Fun';

  @override
  String get settingsSectionAbout => 'About';
}
