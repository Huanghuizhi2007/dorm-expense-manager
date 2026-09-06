import '../../core/chore_calculator.dart';
import '../models/chore_rule.dart';
import '../models/chore_task.dart';
import '../supabase_service.dart';

class ChoreRepository {
  Future<ChoreRule?> fetchRule(String dormitoryId) async {
    final row = await SupabaseService.client
        .from('chore_rules')
        .select()
        .eq('dormitory_id', dormitoryId)
        .maybeSingle();
    if (row == null) return null;
    return ChoreRule.fromMap(row);
  }

  Future<void> saveRule({
    required String dormitoryId,
    required List<String> memberOrder,
    required int intervalDays,
    required DateTime startDate,
  }) async {
    final existing = await fetchRule(dormitoryId);
    final payload = <String, dynamic>{
      'member_order': memberOrder,
      'interval_days': intervalDays,
      'start_date': choreDateKey(startDate),
    };
    if (existing == null) {
      await SupabaseService.client.from('chore_rules').insert(<String, dynamic>{
        'dormitory_id': dormitoryId,
        ...payload,
      });
    } else {
      await SupabaseService.client
          .from('chore_rules')
          .update(payload)
          .eq('id', existing.id);
    }
  }

  Future<List<ChoreTask>> fetchTasks(String dormitoryId) async {
    final rows = await SupabaseService.client
        .from('chore_tasks')
        .select()
        .eq('dormitory_id', dormitoryId)
        .order('task_date', ascending: true);
    return rows.map(ChoreTask.fromMap).toList();
  }

  Future<void> regenerate(ChoreRule rule) async {
    final today = dateOnly(DateTime.now());
    final ruleHorizon = addCalendarDays(rule.startDate, 183);
    final until = today.isAfter(ruleHorizon) ? today : ruleHorizon;
    final horizon = addCalendarDays(today, 183).isAfter(until)
        ? addCalendarDays(today, 183)
        : until;

    await SupabaseService.client
        .from('chore_tasks')
        .delete()
        .eq('dormitory_id', rule.dormitoryId)
        .eq('source', 'auto')
        .eq('status', 'pending')
        .gte('task_date', choreDateKey(today));

    final remaining = await SupabaseService.client
        .from('chore_tasks')
        .select('task_date')
        .eq('dormitory_id', rule.dormitoryId)
        .gte('task_date', choreDateKey(today))
        .lte('task_date', choreDateKey(horizon));
    final occupied = <String>{
      for (final row in remaining) row['task_date'] as String,
    };

    final assignments = buildChoreAssignments(
      memberOrder: rule.memberOrder,
      intervalDays: rule.intervalDays,
      startDate: rule.startDate,
      from: today,
      until: horizon,
    );
    final rows = <Map<String, dynamic>>[
      for (final assignment in assignments)
        if (!occupied.contains(choreDateKey(assignment.date)))
          <String, dynamic>{
            'dormitory_id': rule.dormitoryId,
            'member_id': assignment.memberId,
            'task_date': choreDateKey(assignment.date),
            'source': 'auto',
            'status': 'pending',
          },
    ];
    if (rows.isNotEmpty) {
      await SupabaseService.client.from('chore_tasks').insert(rows);
    }
  }

  Future<ChoreTask?> fetchTaskOnDate(
    String dormitoryId,
    DateTime date,
  ) async {
    final rows = await SupabaseService.client
        .from('chore_tasks')
        .select()
        .eq('dormitory_id', dormitoryId)
        .eq('task_date', choreDateKey(date))
        .limit(1);
    if (rows.isEmpty) return null;
    return ChoreTask.fromMap(rows.first);
  }

  Future<void> setManualTask({
    required String dormitoryId,
    required String memberId,
    required DateTime date,
  }) async {
    final existing = await fetchTaskOnDate(dormitoryId, date);
    if (existing != null && existing.isDone) {
      throw StateError('已经完成的值日不能再调整。');
    }
    final payload = <String, dynamic>{
      'dormitory_id': dormitoryId,
      'member_id': memberId,
      'task_date': choreDateKey(date),
      'source': 'manual',
      'status': 'pending',
      'completed_by': null,
      'completed_at': null,
    };
    if (existing == null) {
      await SupabaseService.client.from('chore_tasks').insert(payload);
    } else {
      await SupabaseService.client
          .from('chore_tasks')
          .update(payload)
          .eq('id', existing.id);
    }
  }

  Future<void> completeTask({
    required ChoreTask task,
    required String completedBy,
  }) async {
    final now = DateTime.now().toUtc();
    await SupabaseService.client
        .from('chore_tasks')
        .update(<String, dynamic>{
          'status': 'done',
          'completed_by': completedBy,
          'completed_at': now.toIso8601String(),
        })
        .eq('id', task.id);
    await SupabaseService.client.from('chore_records').insert(<String, dynamic>{
      'dormitory_id': task.dormitoryId,
      'member_id': task.memberId,
      'task_date': choreDateKey(task.taskDate),
      'status': 'done',
      'is_manual': task.isManual,
      'completed_by': completedBy,
      'completed_at': now.toIso8601String(),
    });
  }
}
