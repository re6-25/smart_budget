import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/badge_provider.dart';
import '../widgets/budget_progress_bar.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exp = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final currency = settings.currency;

    return Scaffold(
      body: exp.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeader(context, exp, settings, theme),
                  ),
                  title: Text(
                    'الميزانية الذكية',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Budget Progress Card
                      _buildBudgetCard(context, exp, settings, theme),
                      const SizedBox(height: 16),
                      // Stats Row
                      _buildStatsRow(context, exp, settings, theme),
                      const SizedBox(height: 16),
                      // Top Categories
                      _buildTopCategories(context, exp, settings, theme),
                      const SizedBox(height: 16),
                      // Recent Expenses
                      _buildRecentExpenses(context, exp, settings, theme),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('إضافة مصروف'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ExpenseProvider exp,
      SettingsProvider settings, ThemeData theme) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مرحباً، ${settings.userName}',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, ExpenseProvider exp,
      SettingsProvider settings, ThemeData theme) {
    final pct = exp.percentUsed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ميزانية اليوم', style: theme.textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getBudgetColor(pct).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: _getBudgetColor(pct),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BudgetProgressBar(percent: pct),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statItem('المُنفَق', '${exp.dailyTotal.toStringAsFixed(2)} ${settings.currency}',
                    _getBudgetColor(pct)),
                _statItem('المتبقي', '${exp.remainingBudget.toStringAsFixed(2)} ${settings.currency}',
                    const Color(0xFF00D4AA)),
                _statItem('الحد', '${exp.dailyLimit.toStringAsFixed(2)} ${settings.currency}',
                    Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBudgetColor(double pct) {
    if (pct < 0.6) return const Color(0xFF00D4AA);
    if (pct < 0.8) return Colors.orange;
    return const Color(0xFFFF4757);
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, ExpenseProvider exp,
      SettingsProvider settings, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _miniStatCard(
            context,
            'إجمالي اليوم',
            '${exp.dailyTotal.toStringAsFixed(2)}',
            settings.currency,
            Icons.today,
            const Color(0xFF00D4AA),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniStatCard(
            context,
            'إجمالي الشهر',
            '${exp.monthlyTotal.toStringAsFixed(2)}',
            settings.currency,
            Icons.calendar_month,
            const Color(0xFFFF6B35),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _miniStatCard(
            context,
            'عدد المصاريف',
            '${exp.expenses.length}',
            'مصروف',
            Icons.receipt_long,
            const Color(0xFFDDA0DD),
          ),
        ),
      ],
    );
  }

  Widget _miniStatCard(BuildContext context, String label, String value,
      String unit, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(unit,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategories(BuildContext context, ExpenseProvider exp,
      SettingsProvider settings, ThemeData theme) {
    final breakdown = exp.categoryBreakdown;
    if (breakdown.isEmpty) return const SizedBox();

    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أعلى الفئات هذا الشهر', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...top.map((entry) {
              final category = exp.getCategoryById(entry.key);
              if (category == null) return const SizedBox();
              final pct = exp.monthlyTotal > 0
                  ? entry.value / exp.monthlyTotal
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: category.color.withOpacity(0.2),
                      radius: 18,
                      child: Icon(category.icon,
                          color: category.color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(category.name,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation(category.color),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${entry.value.toStringAsFixed(0)} ${settings.currency}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentExpenses(BuildContext context, ExpenseProvider exp,
      SettingsProvider settings, ThemeData theme) {
    final recent = exp.expenses.take(5).toList();
    if (recent.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('لا توجد مصاريف بعد',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('أحدث المصاريف', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...recent.map((e) {
              final category = exp.getCategoryById(e.categoryId);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      (category?.color ?? Colors.grey).withOpacity(0.2),
                  child: Icon(
                    category?.icon ?? Icons.money,
                    color: category?.color ?? Colors.grey,
                    size: 20,
                  ),
                ),
                title: Text(category?.name ?? 'أخرى',
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text(e.note ?? e.personName,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: Text(
                  '${e.amount.toStringAsFixed(2)} ${e.currency ?? settings.currency}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
