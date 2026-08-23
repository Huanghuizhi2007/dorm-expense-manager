class DormMember {
  const DormMember({
    required this.id,
    required this.dormitoryId,
    required this.userId,
    required this.username,
    required this.role,
    this.avatarUrl,
    required this.joinedAt,
  });

  final String id;
  final String dormitoryId;
  final String userId;
  final String username;
  final String role;
  final String? avatarUrl;
  final DateTime joinedAt;

  factory DormMember.fromMap(Map<String, dynamic> map) {
    final profile = (map['profile'] ?? map['profiles']) as Map<String, dynamic>?;
    return DormMember(
      id: map['id'] as String,
      dormitoryId: map['dormitory_id'] as String,
      userId: map['user_id'] as String,
      username: (profile?['username'] as String?) ??
          (map['username'] as String?) ??
          '成员',
      role: (map['role'] as String?) ?? 'member',
      avatarUrl: (profile?['avatar_url'] as String?) ??
          (map['avatar_url'] as String?),
      joinedAt: DateTime.tryParse(map['joined_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'dormitory_id': dormitoryId,
      'user_id': userId,
      'username': username,
      'role': role,
      'avatar_url': avatarUrl,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
