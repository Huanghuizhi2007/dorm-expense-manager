import 'dart:io';
import 'dart:convert';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/cache_service.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';
import '../data/supabase_service.dart';

class AuthController extends ChangeNotifier {
  AuthController() {
    _subscription = SupabaseService.client.auth.onAuthStateChange.listen(
      _onAuthStateChanged,
    );
    _restoreSession();
  }

  final AuthRepository _repository = AuthRepository();

  StreamSubscription<AuthState>? _subscription;
  UserProfile? _profile;
  bool _isInitializing = true;
  bool _isLoading = false;
  String? _message;

  UserProfile? get profile => _profile;
  bool get isInitializing => _isInitializing;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _profile != null;
  String? get message => _message;

  Future<void> _restoreSession() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        _profile = await _loadProfile(user.id);
      }
    } catch (_) {
      // 未登录或网络异常时保持初始状态。
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> _onAuthStateChanged(AuthState state) async {
    if (state.event == AuthChangeEvent.signedIn) {
      final userId = state.session?.user.id;
      if (userId != null) {
        try {
          _profile = await _loadProfile(userId);
        } catch (_) {
          // 资料读取失败时允许进入，个人页会显示兜底用户名。
        }
      }
      notifyListeners();
    } else if (state.event == AuthChangeEvent.signedOut) {
      _profile = null;
      _message = null;
      notifyListeners();
    }
  }

  Future<UserProfile?> _loadProfile(String userId) async {
    try {
      final profile = await _repository.fetchProfile(userId);
      await CacheService.cacheProfile(profile!);
      return profile;
    } catch (_) {
      return CacheService.cachedProfile(userId) ??
          UserProfile(
            id: userId,
            username:
                SupabaseService.client.auth.currentUser?.email?.split('@').first ??
                    '成员',
          );
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _message = null;
    notifyListeners();
    try {
      await _repository.signIn(email: email, password: password);
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        _profile = await _loadProfile(user.id);
      }
      return null;
    } catch (error) {
      _message = _repository.friendlyError(error);
      return _message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _message = null;
    notifyListeners();
    try {
      final response = await _repository.signUp(
        username: username,
        email: email,
        password: password,
      );
      if (response.session != null && response.user != null) {
        _profile = await _loadProfile(response.user!.id);
        return null;
      }
      _message = '注册成功，请前往邮箱完成验证后登录。';
      return _message;
    } catch (error) {
      _message = _repository.friendlyError(error);
      return _message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> updateProfile({
    String? username,
    String? avatarUrl,
  }) async {
    final current = _profile;
    if (current == null) return '请先登录';
    try {
      await _repository.updateProfile(
        userId: current.id,
        username: username,
        avatarUrl: avatarUrl,
      );
      _profile = await _loadProfile(current.id);
      notifyListeners();
      return null;
    } catch (error) {
      final message = error.toString();
      if (message.contains('not found') ||
          message.contains('bucket') ||
          message.contains('404')) {
        return '头像存储空间未配置，请先在 Supabase SQL Editor 运行 migration_avatar_storage.sql';
      }
      return '头像上传失败，请检查网络后重试。';
    }
  }

  Future<String?> updateAvatarFromFile(String filePath) async {
    final current = _profile;
    if (current == null) return '请先登录';
    try {
      final file = File(filePath);
      if (!await file.exists()) return '头像文件不存在，请重新选择';

      final dotIndex = filePath.lastIndexOf('.');
      final extension = dotIndex >= 0
          ? filePath.substring(dotIndex + 1).toLowerCase()
          : 'jpg';
      final contentType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      final bytes = await file.readAsBytes();
      if (bytes.length > 900000) {
        return '图片过大，请选择较小的图片';
      }
      final dataUri =
          'data:$contentType;base64,${base64Encode(bytes)}';
      await _repository.updateProfile(
        userId: current.id,
        avatarUrl: dataUri,
      );
      _profile = await _loadProfile(current.id);
      notifyListeners();
      return null;
    } catch (error) {
      return _repository.friendlyError(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
    } catch (_) {
      // 本地会话也会被清理。
    }
    _profile = null;
    _message = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
