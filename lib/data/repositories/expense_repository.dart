import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dorm_member.dart';
import '../models/expense.dart';
import '../supabase_service.dart';

class ExpenseRepository {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<Expense>> fetch({
    required String dormitoryId,
    required List<DormMember> members,
  }) async {
    final rows = await _client
        .from('expenses')
        .select()
        .eq('dormitory_id', dormitoryId)
        .order('created_at', ascending: false);
    return _toModels(rows, members);
  }

  Stream<List<Expense>> watch({
    required String dormitoryId,
    required List<DormMember> members,
  }) {
    return _client
        .from('expenses')
        .stream(primaryKey: <String>['id'])
        .eq('dormitory_id', dormitoryId)
        .order('created_at', ascending: false)
        .map((rows) => _toModels(rows, members));
  }

  Future<Expense> add({
    required String dormitoryId,
    required ExpenseInput input,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('请先登录');
    final row = await _client
        .from('expenses')
        .insert(input.toMap(dormitoryId: dormitoryId, creatorId: user.id))
        .select()
        .single();
    return Expense.fromMap(row);
  }

  Future<void> update({
    required String expenseId,
    required ExpenseInput input,
  }) async {
    final payload = input.toMap(
      dormitoryId: '',
      creatorId: '',
    )..remove('dormitory_id')
      ..remove('creator_id');
    await _client.from('expenses').update(payload).eq('id', expenseId);
  }

  Future<void> delete(String expenseId) async {
    await _client.from('expenses').delete().eq('id', expenseId);
  }

  List<Expense> _toModels(
    List<Map<String, dynamic>> rows,
    List<DormMember> members,
  ) {
    final names = <String, String>{
      for (final member in members) member.userId: member.username,
    };
    return rows
        .map((row) => Expense.fromMap(row, memberNames: names))
        .toList();
  }
}
