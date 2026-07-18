import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../widgets/state_views.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => context.read<ProjectProvider>().markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: provider.status == LoadStatus.loaded
          ? (provider.notifications.isEmpty
              ? const EmptyStateView(message: 'No notifications yet.', icon: Icons.notifications_none)
              : RefreshIndicator(
                  onRefresh: () => provider.load(forceRefresh: true),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final n = provider.notifications[i];
                      return Card(
                        color: n.unread
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.35)
                            : null,
                        child: ListTile(
                          onTap: () => provider.markNotificationRead(n.id),
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                            child: Icon(Icons.campaign_outlined,
                                color: Theme.of(context).colorScheme.primary, size: 20),
                          ),
                          title: Text(
                            n.title,
                            style: TextStyle(fontWeight: n.unread ? FontWeight.bold : FontWeight.normal),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.message),
                                const SizedBox(height: 4),
                                Text(n.time, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          isThreeLine: true,
                          trailing: n.unread
                              ? Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ))
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
