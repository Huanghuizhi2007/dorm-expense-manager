class ChoreRule {
  const ChoreRule({
    required this.id,
    required this.dormitoryId,
    required this.memberOrder,
    required this.intervalDays,
    required this.startDate,
  });

  final String id;
  final String dormitoryId;
  final List<String> memberOrder;
  final int intervalDays;
  final DateTime startDate;

  factory ChoreRule.fromMap(Map<String, dynamic> map) {
    final rawOrder = map['member_order'];
    return ChoreRule(
      id: map['id'] as String,
      dormitoryId: map['dormitory_id'] as String,
      memberOrder: rawOrder == null
          ? <String>[]
          : List<String>.from(rawOrder as List<dynamic>),
      intervalDays: (map['interval_days'] as num?)?.toInt() ?? 1,
      startDate: DateTime.tryParse(map['start_date']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'dormitory_id': dormitoryId,
      'member_order': memberOrder,
      'interval_days': intervalDays,
      'start_date': _dateKey(startDate),
    };
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
