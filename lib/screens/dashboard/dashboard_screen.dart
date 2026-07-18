import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/labeled_progress_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/skeleton_box.dart';
import '../../widgets/state_views.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Road Construction Dashboard'),
        actions: [
          IconButton(
            tooltip: context.select<ProjectProvider, bool>((p) => p.simulateOffline)
                ? 'Go back online (demo)'
                : 'Simulate offline mode (demo)',
            icon: Icon(
              context.select<ProjectProvider, bool>((p) => p.simulateOffline)
                  ? Icons.cloud_off
                  : Icons.cloud_outlined,
            ),
            onPressed: () => context.read<ProjectProvider>().toggleSimulateOffline(),
          ),
          IconButton(
            tooltip: 'Toggle dark mode',
            icon: Icon(context.watch<ThemeProvider>().isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined),
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          if (provider.status == LoadStatus.loading || provider.status == LoadStatus.initial) {
            return const _DashboardSkeleton();
          }
          if (provider.status == LoadStatus.error) {
            return ErrorStateView(
              message: provider.errorMessage ?? 'Something went wrong.',
              onRetry: () => provider.load(forceRefresh: true),
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.load(forceRefresh: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.isOffline) _OfflineBanner(syncedAt: provider.lastSyncedAt),
                if (provider.isOffline) const SizedBox(height: 16),
                LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 600;
                  return GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      SummaryCard(
                        label: 'Total Projects',
                        value: '${provider.totalProjects}',
                        icon: Icons.folder_copy_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SummaryCard(
                        label: 'Completed',
                        value: '${provider.completedCount}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.completed,
                      ),
                      SummaryCard(
                        label: 'Under Progress',
                        value: '${provider.inProgressCount}',
                        icon: Icons.construction_outlined,
                        color: AppColors.inProgress,
                      ),
                      SummaryCard(
                        label: 'Delayed',
                        value: '${provider.delayedCount}',
                        icon: Icons.warning_amber_outlined,
                        color: AppColors.delayed,
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overall Project Progress',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        LabeledProgressBar(
                          label: 'All Districts',
                          value: provider.overallProgress,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Authority-wise Progress', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final entry in provider.authorityWiseProgress.entries) ...[
                          LabeledProgressBar(
                            label: entry.key,
                            value: entry.value / 100,
                          ),
                          const SizedBox(height: 14),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Activity', style: Theme.of(context).textTheme.titleMedium),
                    TextButton(
                      onPressed: () => context.go('/projects'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  child: Column(
                    children: [
                      for (final p in provider.recentActivity)
                        ListTile(
                          onTap: () => context.push('/projects/${p.id}'),
                          leading: CircleAvatar(
                            backgroundColor: statusColor(p.status).withOpacity(0.15),
                            child: Icon(Icons.route, color: statusColor(p.status), size: 20),
                          ),
                          title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text('${p.district} · ${p.authority}'),
                          trailing: StatusBadge(status: p.status),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final DateTime? syncedAt;
  const _OfflineBanner({required this.syncedAt});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final syncedText = syncedAt == null
        ? 'no cached data timestamp available'
        : 'last synced ${_relativeTime(syncedAt!)}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "You're offline - showing cached data ($syncedText).",
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: List.generate(
            4,
            (_) => const SkeletonBox(height: 100, borderRadius: BorderRadius.all(Radius.circular(16))),
          ),
        ),
        const SizedBox(height: 20),
        const SkeletonBox(height: 90, borderRadius: BorderRadius.all(Radius.circular(16))),
        const SizedBox(height: 20),
        const SkeletonBox(height: 160, borderRadius: BorderRadius.all(Radius.circular(16))),
      ],
    );
  }
}
