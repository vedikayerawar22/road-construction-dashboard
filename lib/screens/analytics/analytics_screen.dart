import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../providers/project_provider.dart';
import '../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();

    if (provider.status != LoadStatus.loaded) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analytics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ChartCard(
            title: 'Projects by Status',
            child: _StatusPieChart(provider: provider),
          ),
          const SizedBox(height: 20),
          _ChartCard(
            title: 'Authority-wise Average Progress',
            child: _AuthorityBarChart(provider: provider),
          ),
          const SizedBox(height: 20),
          _ChartCard(
            title: 'Monthly Completion Trend',
            child: _MonthlyLineChart(provider: provider),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(height: 220, child: child),
          ],
        ),
      ),
    );
  }
}

class _StatusPieChart extends StatelessWidget {
  final ProjectProvider provider;
  const _StatusPieChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = {
      'Completed': provider.completedCount,
      'In Progress': provider.inProgressCount,
      'Delayed': provider.delayedCount,
    };
    final colors = {
      'Completed': AppColors.completed,
      'In Progress': AppColors.inProgress,
      'Delayed': AppColors.delayed,
    };
    final total = data.values.fold<int>(0, (s, v) => s + v);

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: data.entries.map((e) {
                final pct = total == 0 ? 0 : (e.value / total * 100);
                return PieChartSectionData(
                  value: e.value.toDouble(),
                  color: colors[e.key],
                  title: '${pct.round()}%',
                  radius: 55,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: data.entries
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, color: colors[e.key]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('${e.key} (${e.value})',
                                style: Theme.of(context).textTheme.bodySmall),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _AuthorityBarChart extends StatelessWidget {
  final ProjectProvider provider;
  const _AuthorityBarChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    final entries = provider.authorityWiseProgress.entries.toList();
    return BarChart(
      BarChartData(
        maxY: 100,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 25),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= entries.length) return const SizedBox.shrink();
                final label = entries[i].key.split(' ').first;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(label, style: const TextStyle(fontSize: 11)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < entries.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: entries[i].value,
                color: AppColors.seed,
                width: 28,
                borderRadius: BorderRadius.circular(6),
              ),
            ]),
        ],
      ),
    );
  }
}

class _MonthlyLineChart extends StatelessWidget {
  final ProjectProvider provider;
  const _MonthlyLineChart({required this.provider});

  static const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
  static const colors = [AppColors.seed, Colors.deepPurple, AppColors.completed];

  @override
  Widget build(BuildContext context) {
    final authorities = provider.authorities;
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 25),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= months.length) return const SizedBox.shrink();
                return Text(months[i], style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        lineBarsData: [
          for (int a = 0; a < authorities.length; a++)
            LineChartBarData(
              spots: [
                for (int m = 0; m < authorities[a].monthlyCompletion.length; m++)
                  FlSpot(m.toDouble(), authorities[a].monthlyCompletion[m].toDouble()),
              ],
              isCurved: true,
              color: colors[a % colors.length],
              barWidth: 3,
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
  }
}
