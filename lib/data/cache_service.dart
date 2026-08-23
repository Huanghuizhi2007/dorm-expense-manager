import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/dorm_member.dart';
import 'models/dormitory.dart';
import 'models/expense.dart';
import 'models/user_profile.dart';

class CacheService {
  CacheService._();

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    final existing = _prefs;
    if (existing != null) return existing;
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    return prefs;
  }

  static Future<void> saveLastDormitory(String userId, String dormitoryId) async {
    final prefs = await _instance;
    await prefs.setString('last_dormitory_$userId', dormitoryId);
  }

  static Future<String?> lastDormitoryId(String userId) async {
    final prefs = await _instance;
    return prefs.getString('last_dormitory_$userId');
  }

  static Future<void> cacheProfile(UserProfile profile) async {
    final prefs = await _instance;
    await prefs.setString('profile_${profile.id}', jsonEncode(profile.toMap()));
  }

  static Future<UserProfile?> cachedProfile(String userId) async {
    final prefs = await _instance;
    final raw = prefs.getString('profile_$userId');
    if (raw == null) return null;
    try {
      return UserProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> cacheDormitory(String userId, Dormitory dormitory) async {
    final prefs = await _instance;
    await prefs.setString('dormitory_$userId', jsonEncode(dormitory.toMap()));
  }

  static Future<Dormitory?> cachedDormitory(String userId) async {
    final prefs = await _instance;
    final raw = prefs.getString('dormitory_$userId');
    if (raw == null) return null;
    try {
      return Dormitory.fromMap(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> cacheMembers(
    String dormitoryId,
    List<DormMember> members,
  ) async {
    final prefs = await _instance;
    final rows = members.map((member) => member.toMap()).toList();
    await prefs.setString('members_$dormitoryId', jsonEncode(rows));
  }

  static Future<List<DormMember>?> cachedMembers(String dormitoryId) async {
    final prefs = await _instance;
    final raw = prefs.getString('members_$dormitoryId');
    if (raw == null) return null;
    try {
      final rows = jsonDecode(raw) as List<dynamic>;
      return rows
          .map((row) => DormMember.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> cacheExpenses(
    String dormitoryId,
    List<Expense> expenses,
  ) async {
    final prefs = await _instance;
    final rows = expenses.map((expense) => expense.toMap()).toList();
    await prefs.setString('expenses_$dormitoryId', jsonEncode(rows));
  }

  static Future<List<Expense>?> cachedExpenses(String dormitoryId) async {
    final prefs = await _instance;
    final raw = prefs.getString('expenses_$dormitoryId');
    if (raw == null) return null;
    try {
      final rows = jsonDecode(raw) as List<dynamic>;
      return rows
          .map((row) => Expense.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
