class Dormitory {
  const Dormitory({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.creatorId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String inviteCode;
  final String creatorId;
  final DateTime createdAt;

  factory Dormitory.fromMap(Map<String, dynamic> map) {
    return Dormitory(
      id: map['id'] as String,
      name: (map['name'] as String?) ?? '我的宿舍',
      inviteCode: (map['invite_code'] as String?) ?? '',
      creatorId: (map['creator_id'] as String?) ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'invite_code': inviteCode,
      'creator_id': creatorId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
