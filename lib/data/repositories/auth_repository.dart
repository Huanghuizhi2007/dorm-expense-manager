import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_constants.dart';
import '../models/user_profile.dart';
import '../supabase_service.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  Future<AuthResponse> signUp({
    required String username,
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: <String, dynamic>{'username': username.trim()},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<UserProfile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row != null) return UserProfile.fromMap(row);
    return UserProfile(
      id: userId,
      username: _client.auth.currentUser?.email?.split('@').first ?? '成员',
      avatarUrl: null,
    );
  }

  Future<void> updateProfile({
    required String userId,
    String? username,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{};
    if (username != null && username.trim().isNotEmpty) {
      payload['username'] = username.trim();
    }
    if (avatarUrl != null) {
      payload['avatar_url'] = avatarUrl.trim().isEmpty ? null : avatarUrl.trim();
    }
    if (payload.isEmpty) return;
    await _client.from('profiles').update(payload).eq('id', userId);
  }

  String friendlyError(Object error) {
    if (error is AuthException) {
      final message = error.message;
      if (message.contains('already registered')) return '该邮箱已经注册，请直接登录。';
      if (message.contains('Invalid login credentials')) return '邮箱或密码不正确。';
      if (message.contains('Email not confirmed')) return '邮箱尚未验证，请先查收验证邮件。';
      return message;
    }
    if (error is PostgrestException) {
      return error.message;
    }
    return '网络连接失败，请稍后重试。';
  }
}

