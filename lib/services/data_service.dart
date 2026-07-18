import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/project_model.dart';
import '../models/authority_model.dart';
import '../models/notification_model.dart';
import 'cache_service.dart';

/// Data layer for the app.
///
/// Reads from a bundled local JSON file to simulate a REST API response,
/// then persists that payload via [CacheService] (shared_preferences) so the
/// app can still render the last-known data if the "network" call fails -
/// this is the offline-caching bonus feature.
///
/// Swap [_fetchFromSource] for a `dio.get(...)` call against a real backend
/// without touching any calling code - the public method signatures already
/// return Futures, so screens/providers won't change.
class DataService {
  final CacheService _cacheService = CacheService();

  Map<String, dynamic>? _memoryCache;
  bool servedFromCache = false;
  DateTime? lastSyncedAt;

  /// Flip this to true to simulate a network outage and exercise the
  /// offline-cache fallback path (e.g. from a debug menu).
  bool simulateOffline = false;

  Future<Map<String, dynamic>> _fetchFromSource() async {
    // Simulate network latency so loading/skeleton states are visible.
    await Future.delayed(const Duration(milliseconds: 400));
    if (simulateOffline) {
      throw Exception('Simulated network failure');
    }
    final raw = await rootBundle.loadString('assets/data/mock_data.json');
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _loadRaw() async {
    if (_memoryCache != null) return _memoryCache!;

    try {
      final data = await _fetchFromSource();
      _memoryCache = data;
      servedFromCache = false;
      // Fire-and-forget persist so a future offline session has this data.
      unawaited(_cacheService.save(jsonEncode(data)));
      lastSyncedAt = DateTime.now();
      return data;
    } catch (_) {
      // "Network" failed - fall back to whatever was last cached on disk.
      final cachedRaw = await _cacheService.read();
      if (cachedRaw != null) {
        _memoryCache = jsonDecode(cachedRaw) as Map<String, dynamic>;
        servedFromCache = true;
        lastSyncedAt = await _cacheService.lastSyncedAt();
        return _memoryCache!;
      }
      rethrow;
    }
  }

  Future<List<Project>> fetchProjects() async {
    final data = await _loadRaw();
    final list = data['projects'] as List;
    return list.map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Authority>> fetchAuthorities() async {
    final data = await _loadRaw();
    final list = data['authorities'] as List;
    return list.map((e) => Authority.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ProjectNotification>> fetchNotifications() async {
    final data = await _loadRaw();
    final list = data['notifications'] as List;
    return list
        .map((e) => ProjectNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Forces a fresh read next time - used for pull-to-refresh.
  void invalidateCache() => _memoryCache = null;
}
