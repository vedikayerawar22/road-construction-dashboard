import 'dart:async';
import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../models/authority_model.dart';
import '../models/notification_model.dart';
import '../services/data_service.dart';

enum LoadStatus { initial, loading, loaded, error }

enum SortOption { nameAsc, completionDesc, completionAsc, delayDesc }

class ProjectProvider extends ChangeNotifier {
  final DataService _service;
  ProjectProvider(this._service);

  // --- raw data ---
  List<Project> _projects = [];
  List<Authority> _authorities = [];
  List<ProjectNotification> _notifications = [];

  LoadStatus status = LoadStatus.initial;
  String? errorMessage;
  bool get isOffline => _service.servedFromCache;
  DateTime? get lastSyncedAt => _service.lastSyncedAt;

  // --- filters (Projects screen) ---
  String _searchQuery = '';
  String? districtFilter;
  String? authorityFilter;
  ProjectStatus? statusFilter;
  SortOption sortOption = SortOption.nameAsc;
  Timer? _debounce;

  // --- compare selection ---
  Project? compareA;
  Project? compareB;

  List<Project> get projects => _projects;
  List<Authority> get authorities => _authorities;
  List<ProjectNotification> get notifications => _notifications;

  List<String> get districts =>
      _projects.map((p) => p.district).toSet().toList()..sort();
  List<String> get authorityNames =>
      _projects.map((p) => p.authority).toSet().toList()..sort();

  int get unreadCount => _notifications.where((n) => n.unread).length;

  bool get simulateOffline => _service.simulateOffline;


  Future<void> toggleSimulateOffline() async {
    _service.simulateOffline = !_service.simulateOffline;
    await load(forceRefresh: true);
  }

  Future<void> load({bool forceRefresh = false}) async {
    status = LoadStatus.loading;
    notifyListeners();
    if (forceRefresh) _service.invalidateCache();
    try {
      final results = await Future.wait([
        _service.fetchProjects(),
        _service.fetchAuthorities(),
        _service.fetchNotifications(),
      ]);
      _projects = results[0] as List<Project>;
      _authorities = results[1] as List<Authority>;
      _notifications = results[2] as List<ProjectNotification>;
      status = LoadStatus.loaded;
    } catch (e) {
      errorMessage = 'Could not load dashboard data. Please try again.';
      status = LoadStatus.error;
    }
    notifyListeners();
  }


  void onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchQuery = query.trim().toLowerCase();
      notifyListeners();
    });
  }

  void setDistrictFilter(String? d) {
    districtFilter = d;
    notifyListeners();
  }

  void setAuthorityFilter(String? a) {
    authorityFilter = a;
    notifyListeners();
  }

  void setStatusFilter(ProjectStatus? s) {
    statusFilter = s;
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    sortOption = option;
    notifyListeners();
  }

  void clearFilters() {
    districtFilter = null;
    authorityFilter = null;
    statusFilter = null;
    _searchQuery = '';
    notifyListeners();
  }

  List<Project> get filteredProjects {
    var list = _projects.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery) ||
          p.contractor.toLowerCase().contains(_searchQuery) ||
          p.district.toLowerCase().contains(_searchQuery);
      final matchesDistrict = districtFilter == null || p.district == districtFilter;
      final matchesAuthority = authorityFilter == null || p.authority == authorityFilter;
      final matchesStatus = statusFilter == null || p.status == statusFilter;
      return matchesSearch && matchesDistrict && matchesAuthority && matchesStatus;
    }).toList();

    switch (sortOption) {
      case SortOption.nameAsc:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.completionDesc:
        list.sort((a, b) => b.completionPercent.compareTo(a.completionPercent));
        break;
      case SortOption.completionAsc:
        list.sort((a, b) => a.completionPercent.compareTo(b.completionPercent));
        break;
      case SortOption.delayDesc:
        list.sort((a, b) => b.delayDays.compareTo(a.delayDays));
        break;
    }
    return list;
  }

  // --- derived stats for Dashboard ---
  int get totalProjects => _projects.length;
  int get completedCount =>
      _projects.where((p) => p.status == ProjectStatus.completed).length;
  int get inProgressCount =>
      _projects.where((p) => p.status == ProjectStatus.inProgress).length;
  int get delayedCount =>
      _projects.where((p) => p.status == ProjectStatus.delayed).length;

  double get overallProgress {
    if (_projects.isEmpty) return 0;
    final sum = _projects.fold<int>(0, (s, p) => s + p.completionPercent);
    return sum / _projects.length / 100;
  }

  Map<String, double> get authorityWiseProgress {
    final Map<String, List<int>> grouped = {};
    for (final p in _projects) {
      grouped.putIfAbsent(p.authority, () => []).add(p.completionPercent);
    }
    return grouped.map((k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length));
  }

  List<Project> get recentActivity {
    final sorted = [..._projects]..sort((a, b) => b.startDate.compareTo(a.startDate));
    return sorted.take(5).toList();
  }

  Project? projectById(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Project> projectsForAuthority(String authority) =>
      _projects.where((p) => p.authority == authority).toList();

  void setCompareA(Project? p) {
    compareA = p;
    notifyListeners();
  }

  void setCompareB(Project? p) {
    compareB = p;
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final n = _notifications.firstWhere((n) => n.id == id);
    n.unread = false;
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _notifications) {
      n.unread = false;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
