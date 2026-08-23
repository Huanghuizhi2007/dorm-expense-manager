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
        .select('*, profiles (username)')
        .eq('dormitory_id', dormitoryId)
        .eq('month', monthKey(month))
        .order('balance', ascending: false);
    return rows
        .map((row) => SettlementEntry.fromMap(row))
        .toList();
  }
}

