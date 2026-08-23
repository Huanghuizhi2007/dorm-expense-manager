class SettlementEntry {
  const SettlementEntry({
    required this.userId,
    required this.username,
    required this.paid,
    required this.share,
    required this.balance,
  });

  final String userId;
  final String username;
  final double paid;
  final double share;
  final double balance;

  factory SettlementEntry.fromRpc(Map<String, dynamic> map) {
    return SettlementEntry(
      userId: map['user_id'] as String,
      username: (map['username'] as String?) ?? '成员',
      paid: ((map['paid'] as num?) ?? 0).toDouble(),
      share: ((map['share'] as num?) ?? 0).toDouble(),
      balance: ((map['balance'] as num?) ?? 0).toDouble(),
    );
  }

  factory SettlementEntry.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return SettlementEntry(
      userId: map['user_id'] as String,
      username: (profile?['username'] as String?) ?? '成员',
      paid: ((map['paid_amount'] as num?) ?? 0).toDouble(),
      share: ((map['share_amount'] as num?) ?? 0).toDouble(),
      balance: ((map['balance'] as num?) ?? 0).toDouble(),
    );
  }
}

