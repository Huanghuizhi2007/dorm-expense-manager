import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient? _client;

  static SupabaseClient get client {
    final value = _client;
    if (value == null) {
      throw StateError('Supabase has not been initialized.');
    }
    return value;
  }

  static Future<void> initialize(String url, String anonKey) async {
    if (_client != null) return;
    await Supabase.initialize(url: url, anonKey: anonKey);
    _client = Supabase.instance.client;
  }
}

