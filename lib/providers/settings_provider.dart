import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/user_config.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  UserConfig _config = UserConfig(
    id: 1,
    userName: 'المستخدم',
    dailyLimit: 100.0,
    currency: 'ر.س',
  );

  bool _isDarkMode = true;

  UserConfig get config => _config;
  bool get isDarkMode => _isDarkMode;
  String get currency => _config.currency;
  double get dailyLimit => _config.dailyLimit;
  String get userName => _config.userName;

  final List<Map<String, String>> currencies = [
    {'symbol': 'ر.س', 'name': 'ريال سعودي'},
    {'symbol': 'د.إ', 'name': 'درهم إماراتي'},
    {'symbol': 'ج.م', 'name': 'جنيه مصري'},
    {'symbol': 'د.ك', 'name': 'دينار كويتي'},
    {'symbol': 'ر.ق', 'name': 'ريال قطري'},
    {'symbol': 'ر.ي', 'name': 'ريال يمني'},
    {'symbol': '\$', 'name': 'دولار أمريكي'},
    {'symbol': '€', 'name': 'يورو'},
  ];

  Future<void> loadConfig() async {
    _config = await _db.getUserConfig();
    notifyListeners();
  }

  Future<void> saveConfig(UserConfig config) async {
    _config = config;
    await _db.updateUserConfig(config);
    notifyListeners();
  }

  Future<void> updateDailyLimit(double limit) async {
    final updated = _config.copyWith(dailyLimit: limit);
    await saveConfig(updated);
  }

  Future<void> updateCurrency(String currency) async {
    final updated = _config.copyWith(currency: currency);
    await saveConfig(updated);
  }

  Future<void> updateUserName(String name) async {
    final updated = _config.copyWith(userName: name);
    await saveConfig(updated);
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
