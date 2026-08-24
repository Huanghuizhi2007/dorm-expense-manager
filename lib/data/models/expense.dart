import '../../core/app_constants.dart';

class Expense {
  const Expense({
    required this.id,
    required this.dormitoryId,
    required this.title,
    required this.amount,
    required this.category,
    required this.payerId,
    required this.creatorId,
    required this.createdAt,
    this.payerName,
    this.payerAvatarUrl,
    this.creatorName,
  });

  final String id;
  final String dormitoryId;
  final String title;
  final double amount;
  final String category;
  final String payerId;
  final String creatorId;
  final DateTime createdAt;
  final String? payerName;
  final String? payerAvatarUrl;
  final String? creatorName;

  factory Expense.fromMap(
    Map<String, dynamic> map, {
    Map<String, String>? memberNames,
  }) {
    final payer = map['payer'] as Map<String, dynamic>?;
    final creator = map['creator'] as Map<String, dynamic>?;
    final payerId = map['payer_id'] as String;

    return Expense(
      id: map['id'] as String,
      dormitoryId: map['dormitory_id'] as String,
      title: (map['title'] as String?) ?? '未命名支出',
      amount: ((map['amount'] as num?) ?? 0).toDouble(),
      category: (map['category'] as String?) ?? '其他',
      payerId: payerId,
      creatorId: map['creator_id'] as String,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      payerName: (payer?['username'] as String?) ??
          (map['payer_name'] as String?) ??
          memberNames?[payerId] ??
          '成员',
      payerAvatarUrl: payer?['avatar_url'] as String?,
      creatorName: creator?['username'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'dormitory_id': dormitoryId,
      'title': title,
      'amount': amount,
      'category': category,
      'payer_id': payerId,
      'creator_id': creatorId,
      'payer_name': payerName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ExpenseInput {
  const ExpenseInput({
    required this.title,
    required this.amount,
    required this.category,
    required this.payerId,
    required this.createdAt,
  });

  final String title;
  final double amount;
  final String category;
  final String payerId;
  final DateTime createdAt;

  Map<String, dynamic> toMap({
    required String dormitoryId,
    required String creatorId,
  }) {
    return <String, dynamic>{
      'dormitory_id': dormitoryId,
      'title': title.trim(),
      'amount': amount.toStringAsFixed(2),
      'category': category,
      'payer_id': payerId,
      'creator_id': creatorId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'expense_date': dateKey(createdAt),
    };
  }
}
