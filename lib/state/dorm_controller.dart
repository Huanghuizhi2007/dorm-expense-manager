import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/cache_service.dart';
import '../data/models/dorm_member.dart';
import '../data/models/dormitory.dart';
import '../data/models/expense.dart';
import '../data/models/settlement_entry.dart';
import '../data/repositories/dormitory_repository.dart';
import '../data/repositories/expense_repository.dart';
import '../data/repositories/settlement_repository.dart';
import '../data/supabase_service.dart';

class DormController extends ChangeNotifier {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final DormitoryRepository _dormitoryRepository = DormitoryRepository();
  final SettlementRepository _settlementRepository = SettlementRepository();

  List<Dormitory> _dormitories = <Dormitory>[];
  Dormitory? _currentDormitory;
  List<DormMember> _members = <DormMember>[];
  List<Expense> _expenses = <Expense>[];
  bool _isLoading = false;
  String? _errorMessage;
  String? _loadedUserId;
  Future<void>? _bootstrapFuture;
  StreamSubscription<List<Expense>>? _expenseSubscription;

  List<Dormitory> get dormitories => _dormitories;
  Dormitory? get currentDormitory => _currentDormitory;
  List<DormMember> get members => _members;
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> bootstrap(String userId) {
    if (_loadedUserId == userId && _bootstrapFuture != null) {
      return _bootstrapFuture!;
    }
    _loadedUserId = userId;
    final future = _doBootstrap(userId);
    _bootstrapFuture = future;
    return future;
  }

  Future<void> _doBootstrap(String userId) async {
    _expenseSubscription?.cancel();
    _expenseSubscription = null;
    _dormitories = <Dormitory>[];
    _currentDormitory = null;
    _members = <DormMember>[];
    _expenses = <Expense>[];
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _loadDormitories(userId);
      if (_dormitories.isEmpty) {
        _currentDormitory = null;
        _members = <DormMember>[];
        _expenses = <Expense>[];
      } else {
        final lastId = await CacheService.lastDormitoryId(userId);
        Dormitory? target;
        for (final dormitory in _dormitories) {
          if (dormitory.id == lastId) target = dormitory;
        }
        await _selectDormitory(target ?? _dormitories.first);
      }
    } catch (error) {
      _errorMessage = _friendlyError(error);
      final cachedDormitory = await CacheService.cachedDormitory(userId);
      if (cachedDormitory != null) {
        _currentDormitory = cachedDormitory;
        _members = await CacheService.cachedMembers(cachedDormitory.id) ??
            <DormMember>[];
        _expenses = await CacheService.cachedExpenses(cachedDormitory.id) ??
            <Expense>[];
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadDormitories(String userId) async {
    final memberRows = await SupabaseService.client
        .from('members')
        .select('dormitory_id')
        .eq('user_id', userId);
    final ids = memberRows
        .map((row) => row['dormitory_id'] as String)
        .toSet()
        .toList();
    if (ids.isEmpty) {
      _dormitories = <Dormitory>[];
      return;
    }
    final rows = await SupabaseService.client
        .from('dormitories')
        .select()
        .inFilter('id', ids);
    _dormitories = rows.map(Dormitory.fromMap).toList();
  }

  Future<void> selectDormitory(Dormitory dormitory) async {
    await _selectDormitory(dormitory);
  }

  Future<void> _selectDormitory(Dormitory dormitory) async {
    _expenseSubscription?.cancel();
    _expenseSubscription = null;
    final userId = _loadedUserId;
    if (userId != null) {
      await CacheService.saveLastDormitory(userId, dormitory.id);
      await CacheService.cacheDormitory(userId, dormitory);
    }
    _currentDormitory = dormitory;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _members = await _fetchMembers(dormitory.id);
      _expenses = await _expenseRepository.fetch(
        dormitoryId: dormitory.id,
        members: _members,
      );
      await _cacheCurrent();
      _startExpenseStream();
    } catch (error) {
      _errorMessage = _friendlyError(error);
      final cachedMembers = await CacheService.cachedMembers(dormitory.id);
      final cachedExpenses = await CacheService.cachedExpenses(dormitory.id);
      if (cachedMembers != null) _members = cachedMembers;
      if (cachedExpenses != null) _expenses = cachedExpenses;
      _startExpenseStream();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<DormMember>> _fetchMembers(String dormitoryId) async {
    final rows = await SupabaseService.client
        .from('members')
        .select()
        .eq('dormitory_id', dormitoryId)
        .order('joined_at', ascending: true);
    final userIds = rows
        .map((row) => row['user_id'] as String)
        .toSet()
        .toList();
    if (userIds.isEmpty) return <DormMember>[];

    final profileRows = await SupabaseService.client
        .from('profiles')
        .select('id, username, avatar_url')
        .inFilter('id', userIds);
    final profilesById = <String, Map<String, dynamic>>{
      for (final profile in profileRows) profile['id'] as String: profile,
    };

    return rows.map((row) {
      final merged = Map<String, dynamic>.from(row);
      final profile = profilesById[row['user_id'] as String];
      if (profile != null) {
        merged['username'] = profile['username'];
        merged['avatar_url'] = profile['avatar_url'];
      }
      return DormMember.fromMap(merged);
    }).toList();
  }

  void _startExpenseStream() {
    final dormitory = _currentDormitory;
    if (dormitory == null) return;
    _expenseSubscription?.cancel();
    _expenseSubscription = _expenseRepository
        .watch(dormitoryId: dormitory.id, members: _members)
        .listen(
          (expenses) {
            _expenses = expenses;
            CacheService.cacheExpenses(dormitory.id, expenses);
            notifyListeners();
          },
          onError: (Object error) {
            _errorMessage = '实时同步连接中断，当前显示本地数据。';
            notifyListeners();
          },
        );
  }

  Future<void> _cacheCurrent() async {
    final dormitory = _currentDormitory;
    if (dormitory == null) return;
    await CacheService.cacheMembers(dormitory.id, _members);
    await CacheService.cacheExpenses(dormitory.id, _expenses);
  }

  Future<void> refresh() async {
    final dormitory = _currentDormitory;
    if (dormitory != null) {
      await _selectDormitory(dormitory);
    }
  }

  Future<void> createDormitory(String name) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final dormitory = await _dormitoryRepository.create(name);
      _dormitories = <Dormitory>[..._dormitories, dormitory];
      await _selectDormitory(dormitory);
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> joinDormitory(String inviteCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final dormitory = await _dormitoryRepository.joinByCode(inviteCode);
      if (!_dormitories.any((item) => item.id == dormitory.id)) {
        _dormitories = <Dormitory>[..._dormitories, dormitory];
      }
      await _selectDormitory(dormitory);
    } catch (error) {
      _errorMessage = _friendlyError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(ExpenseInput input) async {
    final dormitory = _currentDormitory;
    if (dormitory == null) return;
    await _expenseRepository.add(
      dormitoryId: dormitory.id,
      input: input,
    );
    notifyListeners();
  }

  Future<void> updateExpense(String expenseId, ExpenseInput input) async {
    await _expenseRepository.update(expenseId: expenseId, input: input);
    notifyListeners();
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expenseRepository.delete(expenseId);
    notifyListeners();
  }

  Future<List<SettlementEntry>> syncSettlements(DateTime month) async {
    final dormitory = _currentDormitory;
    if (dormitory == null) return <SettlementEntry>[];
    return _settlementRepository.generate(
      dormitoryId: dormitory.id,
      month: month,
    );
  }

  Future<List<SettlementEntry>> fetchSettlements(DateTime month) async {
    final dormitory = _currentDormitory;
    if (dormitory == null) return <SettlementEntry>[];
    return _settlementRepository.fetch(
      dormitoryId: dormitory.id,
      month: month,
    );
  }

  void reset() {
    _expenseSubscription?.cancel();
    _expenseSubscription = null;
    _bootstrapFuture = null;
    _loadedUserId = null;
    _dormitories = <Dormitory>[];
    _currentDormitory = null;
    _members = <DormMember>[];
    _expenses = <Expense>[];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  String _friendlyError(Object error) {
    if (error is PostgrestException) {
      final message = error.message;
      if (message.contains('INVITE_NOT_FOUND')) return '邀请码不存在，请检查后重试。';
      if (message.contains('duplicate key')) return '你已经加入过该宿舍。';
      return message;
    }
    if (error is AuthException) return error.message;
    return '网络连接失败，请稍后重试。';
  }

  @override
  void dispose() {
    _expenseSubscription?.cancel();
    super.dispose();
  }
}
