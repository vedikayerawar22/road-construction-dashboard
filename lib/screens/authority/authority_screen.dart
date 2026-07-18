import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../models/project_model.dart';
import '../../widgets/labeled_progress_bar.dart';
import '../../widgets/project_card.dart';
import '../../widgets/state_views.dart';

class AuthorityScreen extends StatelessWidget {
  const AuthorityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Authority Performance')),
      body: provider.status == LoadStatus.loaded
          ? RefreshIndicator(
              onRefresh: () => provider.load(forceRefresh: true),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: provider.authorityNames.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final name = provider.authorityNames[i];
                  final projects = provider.projectsForAuthority(name);
                  final completed = projects.where((p) => p.status == ProjectStatus.completed).length;
                  final avgProgress = projects.isEmpty
                      ? 0.0
                      : projects.fold<int>(0, (s, p) => s + p.completionPercent) / projects.length / 100;

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _AuthorityProjectsSheet(name: name, projects: projects),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _StatBlock(label: 'Projects', value: '${projects.length}'),
                                _StatBlock(label: 'Completed', value: '$completed'),
                                _StatBlock(label: 'Avg Progress', value: '${(avgProgress * 100).round()}%'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LabeledProgressBar(label: 'Average Progress', value: avgProgress, showPercent: false),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _AuthorityProjectsSheet extends StatelessWidget {
  final String name;
  final List<Project> projects;
  const _AuthorityProjectsSheet({required this.name, required this.projects});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(name, style: Theme.of(context).textTheme.titleLarge),
            ),
            Expanded(
              child: projects.isEmpty
                  ? const EmptyStateView(message: 'No projects for this authority.')
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: projects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => ProjectCard(
                        project: projects[i],
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/projects/${projects[i].id}');
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
