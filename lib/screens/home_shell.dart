import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import 'dashboard_screen.dart';
import 'expense_list_screen.dart';
import 'charts_screen.dart';
import 'export_screen.dart';
import 'settings_screen.dart';
import 'category_manager_screen.dart';
import '../widgets/badge_card.dart';
import '../providers/badge_provider.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  bool _notifiedThisSession = false;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ExpenseListScreen(),
    ChartsScreen(),
    ExportScreen(),
    SettingsScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkNotification();
    _checkBadges();
  }

  void _checkNotification() {
    if (_notifiedThisSession) return;
    final exp = context.read<ExpenseProvider>();
    final settings = context.read<SettingsProvider>();
    if (exp.percentUsed >= 0.8) {
      _notifiedThisSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '⚠️ لقد استهلكت ${(exp.percentUsed * 100).toStringAsFixed(0)}% من ميزانيتك اليومية!',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red.shade800,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  void _checkBadges() {
    final exp = context.read<ExpenseProvider>();
    final badgeProvider = context.read<BadgeProvider>();
    badgeProvider.checkBadges(
      dailyTotal: exp.dailyTotal,
      dailyLimit: exp.dailyLimit,
      totalExpenses: exp.expenses.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'المصاريف',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'التحليل',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf_outlined),
            activeIcon: Icon(Icons.picture_as_pdf),
            label: 'تصدير',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 4
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CategoryManagerScreen()),
              ),
              icon: const Icon(Icons.category),
              label: const Text('الفئات'),
            )
          : null,
    );
  }
}
