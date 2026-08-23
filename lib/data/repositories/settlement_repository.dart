import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_constants.dart';
import '../models/settlement_entry.dart';
import '../supabase_service.dart';

class SettlementRepository {
  SupabaseClient get _client => SupabaseService.client;

  Future<List<SettlementEntry>> generate({
    required String dormitoryId,
    required DateTime month,
  }) async {
    final result = await _client.rpc(
      'generate_monthly_settlements',
      params: <String, dynamic>{
        'p_dormitory_id': dormitoryId,
        'p_month': monthKey(month),
      },
    );
    final rows = result as List<dynamic>;
    return rows
        .map((row) => SettlementEntry.fromRpc(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<SettlementEntry>> fetch({
    required String dormitoryId,
    required DateTime month,
  }) async {
    final rows = await _client
        .from('settlements')
        .select()
        .eq('dormitory_id', dormitoryId)
        .eq('month', monthKey(month))
        .order('balance', ascending: false);
    final userIds = rows
        .map((row) => row['user_id'] as String)
        .toSet()
        .toList();
    if (userIds.isEmpty) return <SettlementEntry>[];

    final profileRows = await _client
        .from('profiles')
        .select('id, username')
        .inFilter('id', userIds);
    final usernames = <String, String>{
      for (final profile in profileRows)
        profile['id'] as String: (profile['username'] as String?) ?? '成员',
    };

    return rows.map((row) {
      final merged = Map<String, dynamic>.from(row);
      final username = usernames[row['user_id'] as String];
      if (username != null) merged['username'] = username;
      return SettlementEntry.fromMap(merged);
    }).toList();
  }
}
