import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/labeled_progress_bar.dart';
import '../../widgets/state_views.dart';
import '../../services/pdf_service.dart';

class ProjectDetailsScreen extends StatelessWidget {
  final String projectId;
  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.projectById(projectId);
    final df = DateFormat('MMM d, yyyy');

    if (project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Details')),
        body: const EmptyStateView(message: 'Project not found.'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onSelected: (value) async {
              if (value == 'preview') {
                await PdfService.previewProjectDetails(project);
              } else if (value == 'share') {
                await PdfService.shareProjectDetails(project);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'preview', child: Text('Preview / Print')),
              PopupMenuItem(value: 'share', child: Text('Share / Save PDF')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(project.name, style: Theme.of(context).textTheme.titleLarge),
                      ),
                      StatusBadge(status: project.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(icon: Icons.location_on_outlined, label: 'District', value: project.district),
                  _InfoRow(icon: Icons.account_balance_outlined, label: 'Authority', value: project.authority),
                  _InfoRow(icon: Icons.engineering_outlined, label: 'Contractor', value: project.contractor),
                  _InfoRow(icon: Icons.straighten_outlined, label: 'Length', value: '${project.lengthKm} km'),
                  _InfoRow(
                    icon: Icons.currency_rupee,
                    label: 'Budget',
                    value: '₹${project.budgetCr} Cr (Spent: ₹${project.spentCr} Cr)',
                  ),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Duration',
                    value: '${df.format(project.startDate)} → ${df.format(project.endDate)}',
                  ),
                  if (project.delayDays > 0)
                    _InfoRow(
                      icon: Icons.warning_amber_outlined,
                      label: 'Delay',
                      value: '${project.delayDays} days',
                      valueColor: AppColors.delayed,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Construction Stages', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final stage in project.stages) ...[
                    LabeledProgressBar(
                      label: stage.name,
                      value: stage.progress / 100,
                      color: stage.progress == 100 ? AppColors.completed : null,
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Timeline', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  for (int i = 0; i < project.timeline.length; i++)
                    _TimelineTile(
                      date: df.format(project.timeline[i].date),
                      event: project.timeline[i].event,
                      isLast: i == project.timeline.length - 1,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Materials Used', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (final m in project.materials)
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(m.name),
                    subtitle: Text(m.quantity),
                    trailing: Chip(label: Text(m.status)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String date;
  final String event;
  final bool isLast;

  const _TimelineTile({required this.date, required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: scheme.outlineVariant)),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: Theme.of(context).textTheme.bodySmall),
                    Text(event, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
