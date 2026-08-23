import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dormitory.dart';
import '../supabase_service.dart';

class DormitoryRepository {
  DormitoryRepository({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  SupabaseClient get _client => SupabaseService.client;

  Future<Dormitory> create(String name) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('请先登录');

    final inviteCode = _generateInviteCode();
    final row = await _client
        .from('dormitories')
        .insert(<String, dynamic>{
          'name': name.trim(),
          'creator_id': user.id,
          'invite_code': inviteCode,
        })
        .select()
        .single();

    await _client.from('members').insert(<String, dynamic>{
      'dormitory_id': row['id'],
      'user_id': user.id,
      'role': 'creator',
    });

    return Dormitory.fromMap(row);
  }

  Future<Dormitory> joinByCode(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) throw StateError('请输入邀请码');

    final result = await _client.rpc(
      'join_dormitory',
      params: <String, dynamic>{'p_invite_code': normalized},
    );
    if (result is List && result.isNotEmpty) {
      return Dormitory.fromMap(result.first as Map<String, dynamic>);
    }
    throw StateError('邀请码不存在或无法加入。');
  }

  String _generateInviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final buffer = StringBuffer();
    for (var index = 0; index < 8; index++) {
      buffer.write(alphabet[_random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }
}

