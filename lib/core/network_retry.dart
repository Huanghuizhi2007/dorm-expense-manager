import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// 判断是否为可安全重试的瞬时网络错误。
///
/// 移动网络在国内访问 Supabase 时偶尔会出现连接被重置
/// （Connection reset by peer / 连接被对端关闭），这类错误通常重试一次
/// 就能恢复，因此不应直接判定为“网络不可用”。
bool isRetryableNetworkError(Object error) {
  if (error is AuthRetryableFetchException) return true;
  if (error is http.ClientException) return true;

  final message = error.toString().toLowerCase();
  return message.contains('connection reset') ||
      message.contains('connection closed') ||
      message.contains('connection terminated') ||
      message.contains('connection refused') ||
      message.contains('connection attempt failed') ||
      message.contains('socketexception') ||
      message.contains('clientexception') ||
      message.contains('network is unreachable') ||
      message.contains('failed host lookup') ||
      message.contains('timed out') ||
      message.contains('timeout') ||
      message.contains('temporarily unavailable');
}

/// 对瞬时网络错误进行有限次重试，避免用户手动反复点击。
Future<T> runWithRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  List<Duration> delays = const <Duration>[
    Duration.zero,
    Duration(milliseconds: 800),
    Duration(milliseconds: 2200),
  ],
}) async {
  Object? lastError;
  StackTrace? lastStackTrace;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await action();
    } catch (error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      if (!isRetryableNetworkError(error) || attempt == maxAttempts - 1) {
        rethrow;
      }
      final delay = attempt < delays.length ? delays[attempt] : delays.last;
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
    }
  }
  Error.throwWithStackTrace(lastError!, lastStackTrace!);
}

/// 重试插入操作，若重试期间发现记录已存在，则返回已有记录。
///
/// 连接被重置时，服务端可能已经写入成功，只是响应没有回到客户端；
/// 这种情况下直接重试会命中唯一约束，因此需要先查询再补插。
Future<T> insertRowWithRetry<T>({
  required Future<T?> Function() findExisting,
  required Future<T> Function() insert,
}) async {
  try {
    return await runWithRetry(insert);
  } catch (error) {
    if (!isRetryableNetworkError(error)) rethrow;
    final existing = await findExisting();
    if (existing != null) return existing;
    rethrow;
  }
}

/// 重试一个“确保存在”的写操作，适用于成员加入等幂等场景。
Future<void> ensureRowWithRetry({
  required Future<bool> Function() exists,
  required Future<void> Function() write,
}) async {
  await runWithRetry(() async {
    if (await exists()) return;
    await write();
  });
}
