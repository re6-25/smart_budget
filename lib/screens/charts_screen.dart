import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exp = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحليلات والرسوم البيانية'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: 'الفئات'),
            Tab(icon: Icon(Icons.show_chart), text: 'الأيام'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPieChartTab(context, exp, settings, theme),
          _buildLineChartTab(context, exp, settings, theme),
        ],
      ),
    );
  }

  Widget _buildPieChartTab(BuildContext context, ExpenseProvider exp,
      SettingsProvider settings, ThemeData theme) {
    final breakdown = exp.categoryBreakdown;
    if (breakdown.isEmpty) {
      return _emptyState('لا توجد بيانات هذا الشهر');
    }

    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('توزيع المصاريف — ${DateFormat('MMMM yyyy', 'ar').format(DateTime.now())}',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            setState(() {
                              if (response?.touchedSection != null) {
                                _touchedIndex = response!.touchedSection!.touchedSectionIndex;
                              } else {
                                _touchedIndex = null;
                              }
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 50,
                        sections: entries.asMap().entries.map((entry) {
                          final i = entry.key;
                          final e = entry.value;
                          final cat = exp.getCategoryById(e.key);
                          final isTouched = _touchedIndex == i;
                          final pct = total > 0 ? (e.value / total * 100) : 0;
                          return PieChartSectionData(
                            color: cat?.color ?? Colors.grey,
                            value: e.value,
                            title: isTouched
                                ? '${pct.toStringAsFixed(1)}%'
                                : '',
                            radius: isTouched ? 80 : 65,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Legend
                  ...entries.map((e) {
                    final cat = exp.getCategoryById(e.key);
                    final pct = total > 0 ? (e.value / total * 100) : 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: cat?.color ?? Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(cat?.name ?? 'أخرى',
                                style: const TextStyle(fontSize: 13)),
                          ),
                          Text(
                            '${e.value.toStringAsFixed(2)} ${settings.currency}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartTab(BuildContext context, ExpenseProvider exp,
      SettingsProvider settings, ThemeData theme) {
    final data = exp.dailyChart;
    if (data.isEmpty) return _emptyState('لا توجد بيانات يومية هذا الشهر');

    final spots = data.asMap().entries.map((entry) {
      final total = (entry.value['total'] as double?) ?? 0.0;
      return FlSpot(entry.key.toDouble(), total);
    }).toList();

    final maxY = data.map((d) => (d['total'] as double?) ?? 0.0)
        .fold<double>(0, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإنفاق اليومي — ${DateFormat('MMMM yyyy', 'ar').format(DateTime.now())}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'إجمالي الشهر: ${exp.monthlyTotal.toStringAsFixed(2)} ${settings.currency}',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 280,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY > 0 ? maxY / 4 : 1,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 55,
                          getTitlesWidget: (v, meta) => Text(
                            v.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (v, meta) {
                            final idx = v.toInt();
                            if (idx >= 0 && idx < data.length) {
                              final date = data[idx]['date'] as String;
                              final day = date.split('-').last;
                              return Text(day,
                                  style: const TextStyle(fontSize: 10));
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: theme.colorScheme.primary,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (spots) => spots.map((s) {
                          return LineTooltipItem(
                            '${s.y.toStringAsFixed(2)} ${settings.currency}',
                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}
