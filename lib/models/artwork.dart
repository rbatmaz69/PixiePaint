import 'dart:io';

class Artwork {
  final String id;
  final String? pageId;
  final bool hasPhoto;
  final int width;
  final int height;
  final DateTime updatedAt;
  final String dirPath;

  const Artwork({
    required this.id,
    required this.pageId,
    this.hasPhoto = false,
    required this.width,
    required this.height,
    required this.updatedAt,
    required this.dirPath,
  });

  File get paintFile => File('$dirPath/paint.png');
  File get thumbFile => File('$dirPath/thumb.png');
  File get backgroundFile => File('$dirPath/background.png');

  Map<String, dynamic> toJson() => {
        'id': id,
        'pageId': pageId,
        'hasPhoto': hasPhoto,
        'width': width,
        'height': height,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static Artwork fromJson(Map<String, dynamic> json, String dirPath) => Artwork(
        id: json['id'] as String,
        pageId: json['pageId'] as String?,
        hasPhoto: json['hasPhoto'] as bool? ?? false,
        width: json['width'] as int,
        height: json['height'] as int,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        dirPath: dirPath,
      );
}
