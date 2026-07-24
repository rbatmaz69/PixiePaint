/// One kid's profile: a name and an animal face. Everything else a profile
/// owns (reward progress, gallery) is keyed off [id] elsewhere.
class Profile {
  final String id;
  final String name;
  final String emoji;

  /// Cuts the painting toolbar down to four tools for this child.
  ///
  /// Fourteen tools are the point of the app for a six-year-old and the
  /// reason a three-year-old only ever taps the first icon. It lives on the
  /// profile rather than in the settings because both children share the
  /// tablet, and the profile is where that difference already is.
  final bool simpleTools;

  const Profile({
    required this.id,
    required this.name,
    required this.emoji,
    this.simpleTools = false,
  });

  Profile copyWith({String? name, String? emoji, bool? simpleTools}) => Profile(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        simpleTools: simpleTools ?? this.simpleTools,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'simpleTools': simpleTools,
      };

  static Profile fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '🦄',
        // Absent in profiles.json written before v8.1, and in backups from
        // then — the full toolbar is the old behaviour, so it is the default.
        simpleTools: json['simpleTools'] as bool? ?? false,
      );
}

/// The animal faces offered when creating or renaming a profile. Kept apart
/// from the sticker emojis so a profile face never looks like a stamp.
const List<String> kProfileEmojis = [
  '🦄', '🐶', '🐱', '🐰', '🦊', '🐼', '🐸', '🦁',
  '🐯', '🐨', '🐷', '🐵', '🐧', '🦉', '🐢', '🐝',
];
