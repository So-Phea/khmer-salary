class AppUser {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final bool isPremium;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl = '',
    this.isPremium = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'isPremium': isPremium,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String? ?? 'user_1',
      name: json['name'] as String? ?? 'Sophea Lan',
      email: json['email'] as String? ?? 'sophea@tica.app',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? avatarUrl,
    bool? isPremium,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
