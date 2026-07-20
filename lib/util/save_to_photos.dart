import 'package:gal/gal.dart';

import '../models/artwork.dart';
import 'share.dart';

/// Exports a saved artwork into the device photo library (album
/// "PixiePaint"). Returns false when access was denied or saving failed —
/// the caller shows a kid-friendly explanation then.
///
/// Like sharing, this leaves the app sandbox, so callers must parent-gate it.
Future<bool> saveArtworkToPhotos(Artwork artwork) async {
  try {
    final png = await composeSavedArtworkPng(artwork);
    if (!await Gal.hasAccess(toAlbum: true)) {
      if (!await Gal.requestAccess(toAlbum: true)) return false;
    }
    await Gal.putImageBytes(png,
        album: 'PixiePaint',
        name: 'pixiepaint_${DateTime.now().millisecondsSinceEpoch}');
    return true;
  } on GalException {
    return false;
  }
}
