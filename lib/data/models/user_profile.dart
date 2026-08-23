class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String username;
  final String? avatarUrl;
  final DateTime? createdAt;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      username: (map['username'] as String?) ?? '成员',
      avatarUrl: map['avatar_url'] as String?,
      createdAt: map['created_at'] == null
          ? null
          : DateTime.tryParse(map['created_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

