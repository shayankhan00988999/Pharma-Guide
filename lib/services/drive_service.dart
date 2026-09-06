import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../models/drive_node.dart';

/// Talks to the Drive folder-tree Apps Script, one folder at a time.
///
/// The backend only ever returns ONE folder's direct contents per
/// request (not the whole tree recursively) — so the root screen
/// after login loads fast regardless of how much has been uploaded,
/// and each subfolder's contents are fetched only when the student
/// actually taps into it.
///
/// Every folder is cached locally under its own key. On a normal
/// (non-refresh) call, a cached folder is returned immediately and a
/// background refresh keeps the cache warm for next time; pull-to-
/// refresh always hits the network and updates the cache.
class DriveService {
  static const _cachePrefix = 'drive_node_cache_v2_';
  static const _timeout = Duration(seconds: 15);

  String _cacheKeyFor(String? folderId) => '$_cachePrefix${folderId ?? 'root'}';

  Future<DriveNode?> _readCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return DriveNode.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(String key, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(json));
  }

  Future<Map<String, dynamic>> _fetchJson({
    String? folderId,
    bool forceRefresh = false,
  }) async {
    Future<http.Response> attempt() async {
      final query = <String, String>{
        if (folderId != null) 'folderId': folderId,
        if (forceRefresh) 'refresh': '1',
      };
      final uri = Uri.parse(AppConfig.folderTreeApiUrl)
          .replace(queryParameters: query.isEmpty ? null : query);
      var response = await http.get(uri).timeout(_timeout);

      if ((response.statusCode == 302 || response.statusCode == 301) &&
          response.headers['location'] != null) {
        response = await http
            .get(Uri.parse(response.headers['location']!))
            .timeout(_timeout);
      }
      return response;
    }

    http.Response response;
    try {
      response = await attempt();
    } on Exception {
      // One retry — most "delay" complaints are a single flaky
      // request on mobile data, not a dead endpoint.
      response = await attempt();
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load notes (${response.statusCode})');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) {
      throw Exception(data['error'] ?? 'Unknown error loading notes');
    }
    return data['data'] as Map<String, dynamic>;
  }

  /// Fetches one folder's direct contents. Pass [folderId] as null for
  /// the root folder (the screen shown right after login). Pass
  /// [forceRefresh] for pull-to-refresh, which always hits the network.
  Future<DriveNode> fetchNode({String? folderId, bool forceRefresh = false}) async {
    final cacheKey = _cacheKeyFor(folderId);

    if (!forceRefresh) {
      final cached = await _readCache(cacheKey);
      if (cached != null) {
        // Serve the cache immediately, refresh quietly in the background.
        _fetchJson(folderId: folderId)
            .then((json) => _writeCache(cacheKey, json))
            .catchError((_) {
          // Background refresh failing is fine — the cache just stays as-is.
        });
        return cached;
      }
    }

    final json = await _fetchJson(folderId: folderId, forceRefresh: forceRefresh);
    await _writeCache(cacheKey, json);
    return DriveNode.fromJson(json);
  }
}
