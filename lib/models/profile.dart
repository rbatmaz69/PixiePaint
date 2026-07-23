/// One kid's profile: a name and an animal face. Everything else a profile
/// owns (reward progress, gallery) is keyed off [id] elsewhere.
class Profile {
  final String id;
  final String name;
  final String emoji;

  const Profile({required this.id, required this.name, required this.emoji});

  Profile copyWith({String? name, String? emoji}) => Profile(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'emoji': emoji};

  static Profile fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        emoji: json['emoji'] as String? ?? '🦄',
      );
}

/// The animal faces offered when creating or renaming a profile. Kept apart
/// from the sticker emojis so a profile face never looks like a stamp.
const List<String> kProfileEmojis = [
  '🦄', '🐶', '🐱', '🐰', '🦊', '🐼', '🐸', '🦁',
  '🐯', '🐨', '🐷', '🐵', '🐧', '🦉', '🐢', '🐝',
];
