import 'dart:io';

class Artwork {
  final String id;
  final String? pageId;
  final bool hasPhoto;
  final bool hasPhotoLineArt;
  final int width;
  final int height;
  final DateTime updatedAt;
  final String dirPath;

  /// Kid-given name shown on the polaroid frame; empty/null = unnamed.
  final String? name;
  final bool favorite;

  /// Tracing template this artwork was drawn on (trace mode); the guide is
  /// regenerated from this id on resume.
  final String? traceId;

  const Artwork({
    required this.id,
    required this.pageId,
    this.hasPhoto = false,
    this.hasPhotoLineArt = false,
    required this.width,
    required this.height,
    required this.updatedAt,
    required this.dirPath,
    this.name,
    this.favorite = false,
    this.traceId,
  });

  File get paintFile => File('$dirPath/paint.png');
  File get thumbFile => File('$dirPath/thumb.png');
  File get backgroundFile => File('$dirPath/background.png');
  File get lineArtFile => File('$dirPath/lineart.png');

  Artwork copyWith({String? name, bool? favorite}) => Artwork(
        id: id,
        pageId: pageId,
        hasPhoto: hasPhoto,
        hasPhotoLineArt: hasPhotoLineArt,
        width: width,
        height: height,
        updatedAt: updatedAt,
        dirPath: dirPath,
        name: name ?? this.name,
        favorite: favorite ?? this.favorite,
        traceId: traceId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'pageId': pageId,
        'hasPhoto': hasPhoto,
        'hasPhotoLineArt': hasPhotoLineArt,
        'width': width,
        'height': height,
        'updatedAt': updatedAt.toIso8601String(),
        if (name != null) 'name': name,
        'favorite': favorite,
        if (traceId != null) 'traceId': traceId,
      };

  static Artwork fromJson(Map<String, dynamic> json, String dirPath) => Artwork(
        id: json['id'] as String,
        pageId: json['pageId'] as String?,
        hasPhoto: json['hasPhoto'] as bool? ?? false,
        hasPhotoLineArt: json['hasPhotoLineArt'] as bool? ?? false,
        width: json['width'] as int,
        height: json['height'] as int,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        dirPath: dirPath,
        // Older meta.json files predate these fields.
        name: json['name'] as String?,
        favorite: json['favorite'] as bool? ?? false,
        traceId: json['traceId'] as String?,
      );
}
