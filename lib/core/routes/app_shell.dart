import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShell({super.key, required this.child, required this.location});

  static const _tabs = [
    ('/dashboard', Icons.dashboard_outlined, Icons.dashboard, 'Dashboard'),
    ('/projects', Icons.list_alt_outlined, Icons.list_alt, 'Projects'),
    ('/authorities', Icons.account_balance_outlined, Icons.account_balance, 'Authorities'),
    ('/analytics', Icons.bar_chart_outlined, Icons.bar_chart, 'Analytics'),
    ('/notifications', Icons.notifications_outlined, Icons.notifications, 'Alerts'),
  ];

  int _currentIndex() {
    final index = _tabs.indexWhere((t) => location.startsWith(t.$1));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<ProjectProvider, int>((p) => p.unreadCount);
    final index = _currentIndex();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].$1),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: t.$4 == 'Alerts' && unread > 0
                  ? Badge(label: Text('$unread'), child: Icon(t.$2))
                  : Icon(t.$2),
              selectedIcon: Icon(t.$3),
              label: t.$4,
            ),
        ],
      ),
    );
  }
}
