class ChoreTask {
  const ChoreTask({
    required this.id,
    required this.dormitoryId,
    required this.memberId,
    required this.taskDate,
    required this.source,
    required this.status,
    this.completedBy,
    this.completedAt,
  });

  final String id;
  final String dormitoryId;
  final String memberId;
  final DateTime taskDate;
  final String source;
  final String status;
  final String? completedBy;
  final DateTime? completedAt;

  bool get isDone => status == 'done';
  bool get isManual => source == 'manual';

  factory ChoreTask.fromMap(Map<String, dynamic> map) {
    return ChoreTask(
      id: map['id'] as String,
      dormitoryId: map['dormitory_id'] as String,
      memberId: map['member_id'] as String,
      taskDate: DateTime.tryParse(map['task_date']?.toString() ?? '') ??
          DateTime.now(),
      source: (map['source'] as String?) ?? 'auto',
      status: (map['status'] as String?) ?? 'pending',
      completedBy: map['completed_by'] as String?,
      completedAt: map['completed_at'] == null
          ? null
          : DateTime.tryParse(map['completed_at'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'dormitory_id': dormitoryId,
      'member_id': memberId,
      'task_date': _dateKey(taskDate),
      'source': source,
      'status': status,
      'completed_by': completedBy,
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
