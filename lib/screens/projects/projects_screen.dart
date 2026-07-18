import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../models/project_model.dart';
import '../../widgets/project_card.dart';
import '../../widgets/skeleton_box.dart';
import '../../widgets/state_views.dart';
import '../../services/pdf_service.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  bool _filtersExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: 'Compare Projects',
            onPressed: () => context.push('/compare'),
          ),
          Consumer<ProjectProvider>(
            builder: (context, provider, _) => PopupMenuButton<String>(
              tooltip: 'Export list as PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onSelected: (value) async {
                final list = provider.filteredProjects;
                if (value == 'preview') {
                  await PdfService.previewProjectList(list);
                } else if (value == 'share') {
                  await PdfService.shareProjectList(list);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'preview', child: Text('Preview / Print')),
                PopupMenuItem(value: 'share', child: Text('Share / Save PDF')),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_filtersExpanded ? Icons.filter_alt : Icons.filter_alt_outlined),
            onPressed: () => setState(() => _filtersExpanded = !_filtersExpanded),
            tooltip: 'Filters',
          ),
        ],
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: provider.onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search by name, contractor, district',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                child: _filtersExpanded
                    ? _FilterPanel(provider: provider)
                    : const SizedBox(width: double.infinity),
              ),
              Expanded(
                child: Builder(builder: (context) {
                  if (provider.status == LoadStatus.loading ||
                      provider.status == LoadStatus.initial) {
                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: 5,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, __) => const ProjectCardSkeleton(),
                    );
                  }
                  if (provider.status == LoadStatus.error) {
                    return ErrorStateView(
                      message: provider.errorMessage ?? 'Something went wrong.',
                      onRetry: () => provider.load(forceRefresh: true),
                    );
                  }
                  final list = provider.filteredProjects;
                  if (list.isEmpty) {
                    return const EmptyStateView(
                      message: 'No projects match your filters.',
                      icon: Icons.search_off,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () => provider.load(forceRefresh: true),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final p = list[i];
                        return ProjectCard(
                          project: p,
                          onTap: () => context.push('/projects/${p.id}'),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final ProjectProvider provider;
  const _FilterPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DropdownFilter(
                hint: 'District',
                value: provider.districtFilter,
                items: provider.districts,
                onChanged: provider.setDistrictFilter,
              ),
              _DropdownFilter(
                hint: 'Authority',
                value: provider.authorityFilter,
                items: provider.authorityNames,
                onChanged: provider.setAuthorityFilter,
              ),
              _StatusDropdown(provider: provider),
              _SortDropdown(provider: provider),
            ],
          ),
          if (provider.districtFilter != null ||
              provider.authorityFilter != null ||
              provider.statusFilter != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: provider.clearFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear filters'),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownFilter({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(hintText: hint, isDense: true),
        items: [
          DropdownMenuItem(value: null, child: Text('All ${hint}s')),
          ...items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final ProjectProvider provider;
  const _StatusDropdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<ProjectStatus?>(
        value: provider.statusFilter,
        isExpanded: true,
        decoration: const InputDecoration(hintText: 'Status', isDense: true),
        items: [
          const DropdownMenuItem(value: null, child: Text('All Statuses')),
          ...ProjectStatus.values
              .map((s) => DropdownMenuItem(value: s, child: Text(s.label))),
        ],
        onChanged: provider.setStatusFilter,
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final ProjectProvider provider;
  const _SortDropdown({required this.provider});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: DropdownButtonFormField<SortOption>(
        value: provider.sortOption,
        isExpanded: true,
        decoration: const InputDecoration(hintText: 'Sort by', isDense: true),
        items: const [
          DropdownMenuItem(value: SortOption.nameAsc, child: Text('Name (A-Z)')),
          DropdownMenuItem(value: SortOption.completionDesc, child: Text('Completion (High-Low)')),
          DropdownMenuItem(value: SortOption.completionAsc, child: Text('Completion (Low-High)')),
          DropdownMenuItem(value: SortOption.delayDesc, child: Text('Most Delayed')),
        ],
        onChanged: (v) {
          if (v != null) provider.setSortOption(v);
        },
      ),
    );
  }
}
