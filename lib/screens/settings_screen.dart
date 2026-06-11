import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/expense_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _limitController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>();
    _limitController =
        TextEditingController(text: settings.dailyLimit.toString());
    _nameController = TextEditingController(text: settings.userName);
  }

  @override
  void dispose() {
    _limitController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _sectionHeader(context, 'الملف الشخصي', Icons.person),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onSubmitted: (v) => settings.updateUserName(v),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      settings.updateUserName(_nameController.text);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حفظ الاسم')),
                      );
                    },
                    child: const Text('حفظ الاسم'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Budget Section
          _sectionHeader(context, 'الميزانية', Icons.account_balance_wallet),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _limitController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'الحد اليومي',
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                      suffixText: settings.currency,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final limit = double.tryParse(_limitController.text);
                      if (limit != null && limit > 0) {
                        settings.updateDailyLimit(limit);
                        context.read<ExpenseProvider>().setDailyLimit(limit);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم تحديث الحد اليومي')),
                        );
                      }
                    },
                    child: const Text('تحديث الحد اليومي'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Currency Section
          _sectionHeader(context, 'العملة', Icons.currency_exchange),
          Card(
            child: Column(
              children: settings.currencies.map((c) {
                final selected = settings.currency == c['symbol'];
                return RadioListTile<String>(
                  value: c['symbol']!,
                  groupValue: settings.currency,
                  title: Text('${c['name']} (${c['symbol']})'),
                  activeColor: theme.colorScheme.primary,
                  onChanged: (v) {
                    if (v != null) settings.updateCurrency(v);
                  },
                  selected: selected,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Theme Section
          _sectionHeader(context, 'المظهر', Icons.palette),
          Card(
            child: SwitchListTile(
              title: const Text('الوضع الداكن'),
              subtitle: Text(settings.isDarkMode ? 'مفعّل' : 'مُعطَّل'),
              secondary: Icon(
                settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: theme.colorScheme.primary,
              ),
              value: settings.isDarkMode,
              activeColor: theme.colorScheme.primary,
              onChanged: (_) => settings.toggleTheme(),
            ),
          ),
          const SizedBox(height: 16),

          // App Info
          _sectionHeader(context, 'عن التطبيق', Icons.info_outline),
          Card(
            child: Column(
              children: [
                _infoTile('الإصدار', '1.0.0', Icons.new_releases),
                _infoTile('الحجم', '< 20 MB', Icons.storage),
                _infoTile('قاعدة البيانات', 'SQLite محلي', Icons.lock_outline),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(value, style: const TextStyle(color: Colors.grey)),
    );
  }
}
