import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../core/app_info.dart';

class UpdateInfo {
  const UpdateInfo({required this.version, required this.url});

  final String version;
  final String url;
}

class UpdateService {
  UpdateService._();

  static Future<UpdateInfo?> checkLatest() async {
    final fromSupabase = await _checkSupabase();
    if (fromSupabase != null) return fromSupabase;
    return _checkGitHub();
  }

  static Future<UpdateInfo?> _checkSupabase() async {
    if (!AppConfig.isConfigured) return null;
    try {
      final uri = Uri.parse('${AppConfig.supabaseUrl}/rest/v1/app_releases')
          .replace(
            queryParameters: <String, String>{
              'select': 'version,url',
              'order': 'created_at.desc',
              'limit': '1',
            },
          );
      final response = await http
          .get(
            uri,
            headers: <String, String>{
              'apikey': AppConfig.supabaseAnonKey,
            },
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final rows = jsonDecode(response.body) as List<dynamic>;
      if (rows.isEmpty) return null;
      final row = rows.first as Map<String, dynamic>;
      final version = (row['version'] as String? ?? '').trim();
      final url = row['url'] as String? ?? '';
      if (version.isEmpty || url.isEmpty) return null;
      return UpdateInfo(version: version, url: url);
    } catch (_) {
      return null;
    }
  }

  static Future<UpdateInfo?> _checkGitHub() async {
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/Huanghuizhi2007/'
              'dorm-expense-manager/releases/latest',
            ),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = data['tag_name'] as String? ?? '';
      final version = tag.replaceFirst('v', '').trim();
      if (version.isEmpty) return null;

      final htmlUrl = data['html_url'] as String? ?? AppInfo.releasesUrl;
      return UpdateInfo(version: version, url: htmlUrl);
    } catch (_) {
      return null;
    }
  }

  static bool isNewer(String latest, String current) {
    final latestParts = _parts(latest);
    final currentParts = _parts(current);
    final length = latestParts.length > currentParts.length
        ? latestParts.length
        : currentParts.length;
    for (var i = 0; i < length; i++) {
      final left = i < latestParts.length ? latestParts[i] : 0;
      final right = i < currentParts.length ? currentParts[i] : 0;
      if (left != right) return left > right;
    }
    return false;
  }

  static List<int> _parts(String version) {
    return version
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
  }
}
