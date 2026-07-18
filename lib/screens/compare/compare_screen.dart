import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../models/project_model.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/labeled_progress_bar.dart';
import '../../widgets/state_views.dart';

class CompareScreen extends StatelessWidget {
  const CompareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Projects')),
      body: provider.status == LoadStatus.loaded
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _ProjectPicker(
                        label: 'Project A',
                        value: provider.compareA,
                        projects: provider.projects,
                        onChanged: provider.setCompareA,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ProjectPicker(
                        label: 'Project B',
                        value: provider.compareB,
                        projects: provider.projects,
                        onChanged: provider.setCompareB,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (provider.compareA != null && provider.compareB != null)
                  _ComparisonTable(a: provider.compareA!, b: provider.compareB!)
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: EmptyStateView(
                      message: 'Select two projects above to compare.',
                      icon: Icons.compare_arrows,
                    ),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ProjectPicker extends StatelessWidget {
  final String label;
  final Project? value;
  final List<Project> projects;
  final ValueChanged<Project?> onChanged;

  const _ProjectPicker({
    required this.label,
    required this.value,
    required this.projects,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        DropdownButtonFormField<Project>(
          value: value,
          isExpanded: true,
          decoration: const InputDecoration(hintText: 'Select project', isDense: true),
          items: projects
              .map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.name, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ComparisonTable extends StatelessWidget {
  final Project a;
  final Project b;

  const _ComparisonTable({required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: StatusBadge(status: a.status)),
                    const SizedBox(width: 40),
                    Expanded(child: Align(alignment: Alignment.centerRight, child: StatusBadge(status: b.status))),
                  ],
                ),
                const SizedBox(height: 16),
                _CompareRow(label: 'Progress', valueA: '${a.completionPercent}%', valueB: '${b.completionPercent}%'),
                const SizedBox(height: 10),
                _DualProgress(a: a.completionPercent / 100, b: b.completionPercent / 100),
                const SizedBox(height: 16),
                _CompareRow(label: 'Contractor', valueA: a.contractor, valueB: b.contractor),
                _CompareRow(label: 'Authority', valueA: a.authority, valueB: b.authority),
                _CompareRow(label: 'District', valueA: a.district, valueB: b.district),
                _CompareRow(label: 'Length', valueA: '${a.lengthKm} km', valueB: '${b.lengthKm} km'),
                _CompareRow(label: 'Budget', valueA: '₹${a.budgetCr} Cr', valueB: '₹${b.budgetCr} Cr'),
                _CompareRow(label: 'Spent', valueA: '₹${a.spentCr} Cr', valueB: '₹${b.spentCr} Cr'),
                _CompareRow(
                  label: 'Delay',
                  valueA: a.delayDays > 0 ? '${a.delayDays} days' : 'On Track',
                  valueB: b.delayDays > 0 ? '${b.delayDays} days' : 'On Track',
                  colorA: a.delayDays > 0 ? AppColors.delayed : AppColors.completed,
                  colorB: b.delayDays > 0 ? AppColors.delayed : AppColors.completed,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DualProgress extends StatelessWidget {
  final double a;
  final double b;
  const _DualProgress({required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: LabeledProgressBar(label: 'A', value: a, color: AppColors.seed)),
        const SizedBox(width: 16),
        Expanded(child: LabeledProgressBar(label: 'B', value: b, color: Colors.deepPurple)),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String valueA;
  final String valueB;
  final Color? colorA;
  final Color? colorB;

  const _CompareRow({
    required this.label,
    required this.valueA,
    required this.valueB,
    this.colorA,
    this.colorB,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              )),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(valueA,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600, color: colorA)),
              ),
              Expanded(
                child: Text(valueB,
                    textAlign: TextAlign.right,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600, color: colorB)),
              ),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}
