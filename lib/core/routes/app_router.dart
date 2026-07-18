import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/projects/projects_screen.dart';
import '../../screens/project_details/project_details_screen.dart';
import '../../screens/compare/compare_screen.dart';
import '../../screens/authority/authority_screen.dart';
import '../../screens/analytics/analytics_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import 'app_shell.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(
        location: state.matchedLocation,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/projects',
          builder: (context, state) => const ProjectsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              parentNavigatorKey: rootNavigatorKey,
              builder: (context, state) =>
                  ProjectDetailsScreen(projectId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: '/authorities',
          builder: (context, state) => const AuthorityScreen(),
        ),
        GoRoute(
          path: '/analytics',
          builder: (context, state) => const AnalyticsScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/compare',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CompareScreen(),
    ),
  ],
);
