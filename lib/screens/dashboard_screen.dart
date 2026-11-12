import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../providers/theme_provider.dart';
import 'about_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإحصائيات'),
        actions: <Widget>[
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: () => _showSettingsSheet(context),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, provider, child) {
          final visibleTasks = provider.tasks
              .where((task) => !task.isHidden)
              .toList(growable: false);

          final totalTasks = visibleTasks.length;
          final completedTasks = visibleTasks
              .where((task) => task.status == Task.completedStatus)
              .length;
          final pendingTasks = visibleTasks
              .where(
                (task) =>
                    task.status == Task.pendingStatus ||
                    task.status == Task.overdueStatus,
              )
              .length;

          if (totalTasks == 0) {
            return const Center(child: Text('لا توجد بيانات لهذا التاريخ.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _SummaryCard(
                        countKey: 'total_tasks_count',
                        label: 'الكل',
                        value: totalTasks,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        countKey: 'completed_tasks_count',
                        label: 'المنجزة',
                        value: completedTasks,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        countKey: 'pending_tasks_count',
                        label: 'المتبقية',
                        value: pendingTasks,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'تقدم المهام',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 280,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 48,
                              sections: <PieChartSectionData>[
                                if (completedTasks > 0)
                                  _buildPieSection(
                                    label: 'المنجزة',
                                    value: completedTasks,
                                    total: totalTasks,
                                    color: Colors.green,
                                  ),
                                if (pendingTasks > 0)
                                  _buildPieSection(
                                    label: 'المتبقية',
                                    value: pendingTasks,
                                    total: totalTasks,
                                    color: Colors.orange,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => const _SettingsSheet(),
    );
  }

  PieChartSectionData _buildPieSection({
    required String label,
    required int value,
    required int total,
    required Color color,
  }) {
    final percentage = (value / total * 100).round();

    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      radius: 90,
      title: '$label\n$value ($percentage%)',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      titlePositionPercentageOffset: 0.58,
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  static const List<({String id, String name, Color color})> _themeColors =
      <({String id, String name, Color color})>[
        (id: 'indigo', name: 'نيلي', color: Colors.indigo),
        (id: 'teal', name: 'فيروزي', color: Colors.teal),
        (id: 'green', name: 'أخضر', color: Colors.green),
        (id: 'orange', name: 'برتقالي', color: Colors.orange),
        (id: 'purple', name: 'بنفسجي', color: Colors.purple),
      ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'الإعدادات',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('الوضع الداكن'),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: provider.isDarkMode,
                onChanged: provider.toggleDarkMode,
              ),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                'لون التطبيق',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: _themeColors
                    .map((themeColor) {
                      final isSelected =
                          provider.primaryColorValue ==
                          themeColor.color.toARGB32();

                      return Tooltip(
                        message: themeColor.name,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: ValueKey<String>(
                              'theme_color_${themeColor.id}',
                            ),
                            customBorder: const CircleBorder(),
                            onTap: () =>
                                provider.changePrimaryColor(themeColor.color),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: themeColor.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
              const SizedBox(height: 12),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('عن التطبيق'),
                trailing: const Icon(Icons.info_outline),
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.countKey,
    required this.label,
    required this.value,
    required this.color,
  });

  final String countKey;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        child: Column(
          children: <Widget>[
            Text(
              '$value',
              key: ValueKey<String>(countKey),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
