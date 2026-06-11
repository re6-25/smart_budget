import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/user_config.dart';

/// Cross-platform storage using Hive (works on Android, iOS, and Web).
/// Replaces sqflite which does not support Flutter Web.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const _expensesBox = 'expenses';
  static const _categoriesBox = 'categories';
  static const _usersBox = 'users';
  static const _metaBox = 'meta';

  /// Call this once at app startup (before runApp).
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_expensesBox);
    await Hive.openBox<Map>(_categoriesBox);
    await Hive.openBox<Map>(_usersBox);
    await Hive.openBox(_metaBox);
    await _seedIfNeeded();
  }

  // ─── Seeding ────────────────────────────────────────────────────────────────

  static Future<void> _seedIfNeeded() async {
    final meta = Hive.box(_metaBox);
    if (meta.get('seeded') == true) return;

    final catBox = Hive.box<Map>(_categoriesBox);
    final defaultCategories = [
      {'id': 1, 'name': 'طعام وشراب', 'icon_code': 0xe25a, 'color_hex': 'FF6B6B'},
      {'id': 2, 'name': 'مواصلات',   'icon_code': 0xe1d3, 'color_hex': '4ECDC4'},
      {'id': 3, 'name': 'فواتير',    'icon_code': 0xe0ae, 'color_hex': 'FFE66D'},
      {'id': 4, 'name': 'صحة',       'icon_code': 0xe3f3, 'color_hex': 'A8E6CF'},
      {'id': 5, 'name': 'ترفيه',    'icon_code': 0xe40c, 'color_hex': 'DDA0DD'},
      {'id': 6, 'name': 'تسوق',     'icon_code': 0xe59c, 'color_hex': 'F7DC6F'},
      {'id': 7, 'name': 'تعليم',    'icon_code': 0xe80c, 'color_hex': '85C1E9'},
      {'id': 8, 'name': 'أخرى',     'icon_code': 0xe8b8, 'color_hex': 'AED6F1'},
    ];
    for (final cat in defaultCategories) {
      catBox.put(cat['id'], cat);
    }

    final userBox = Hive.box<Map>(_usersBox);
    userBox.put(1, {
      'id': 1,
      'user_name': 'المستخدم',
      'daily_limit': 100.0,
      'currency': 'ر.س',
    });

    meta.put('seeded', true);
    meta.put('expense_next_id', 1);
    meta.put('category_next_id', 9); // after 8 defaults
  }

  // ─── EXPENSES ───────────────────────────────────────────────────────────────

  Future<int> insertExpense(Expense expense) async {
    final box = Hive.box<Map>(_expensesBox);
    final meta = Hive.box(_metaBox);
    final id = (meta.get('expense_next_id') as int?) ?? 1;
    final map = expense.toMap()..['id'] = id;
    await box.put(id, map);
    await meta.put('expense_next_id', id + 1);
    return id;
  }

  Future<int> updateExpense(Expense expense) async {
    final box = Hive.box<Map>(_expensesBox);
    await box.put(expense.id, expense.toMap());
    return 1;
  }

  Future<int> deleteExpense(int id) async {
    final box = Hive.box<Map>(_expensesBox);
    await box.delete(id);
    return 1;
  }

  Future<List<Expense>> getAllExpenses() async {
    final box = Hive.box<Map>(_expensesBox);
    final items = box.values
        .map((m) => Expense.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<List<Expense>> getExpensesByDate(String date) async {
    final box = Hive.box<Map>(_expensesBox);
    final items = box.values
        .where((m) => m['date'] == date)
        .map((m) => Expense.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    items.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return items;
  }

  Future<List<Expense>> getExpensesByDateRange(
      String startDate, String endDate) async {
    final box = Hive.box<Map>(_expensesBox);
    final items = box.values
        .where((m) {
          final date = m['date'] as String;
          // Use compareTo() — String has no >= / <= operators in Dart
          return date.compareTo(startDate) >= 0 &&
              date.compareTo(endDate) <= 0;
        })
        .map((m) => Expense.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<List<Expense>> getExpensesByCategory(int categoryId) async {
    final box = Hive.box<Map>(_expensesBox);
    final items = box.values
        .where((m) => m['category_id'] == categoryId)
        .map((m) => Expense.fromMap(Map<String, dynamic>.from(m)))
        .toList();
    items.sort((a, b) => b.date.compareTo(a.date));
    return items;
  }

  Future<double> getDailyTotal(String date) async {
    final box = Hive.box<Map>(_expensesBox);
    // Explicitly type the fold accumulator as double to avoid FutureOr<double> inference
    return box.values
        .where((m) => m['date'] == date)
        .fold<double>(
          0.0,
          (sum, m) => sum + (m['amount'] as num).toDouble(),
        );
  }

  Future<double> getMonthlyTotal(String yearMonth) async {
    final box = Hive.box<Map>(_expensesBox);
    // Explicitly type the fold accumulator as double to avoid FutureOr<double> inference
    return box.values
        .where((m) => (m['date'] as String).startsWith(yearMonth))
        .fold<double>(
          0.0,
          (sum, m) => sum + (m['amount'] as num).toDouble(),
        );
  }

  Future<Map<int, double>> getCategoryBreakdown(
      String startDate, String endDate) async {
    final box = Hive.box<Map>(_expensesBox);
    final result = <int, double>{};
    for (final m in box.values) {
      final date = m['date'] as String;
      // Use compareTo() — String has no >= / <= operators in Dart
      if (date.compareTo(startDate) >= 0 && date.compareTo(endDate) <= 0) {
        final catId = m['category_id'] as int;
        final amount = (m['amount'] as num).toDouble();
        result[catId] = (result[catId] ?? 0.0) + amount;
      }
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getDailyTotalsForMonth(
      String yearMonth) async {
    final box = Hive.box<Map>(_expensesBox);
    final totals = <String, double>{};
    for (final m in box.values) {
      final date = m['date'] as String;
      if (date.startsWith(yearMonth)) {
        totals[date] = (totals[date] ?? 0.0) + (m['amount'] as num).toDouble();
      }
    }
    return totals.entries
        .map((e) => {'date': e.key, 'total': e.value})
        .toList()
      ..sort((a, b) =>
          (a['date'] as String).compareTo(b['date'] as String));
  }

  // ─── CATEGORIES ─────────────────────────────────────────────────────────────

  Future<List<Category>> getAllCategories() async {
    final box = Hive.box<Map>(_categoriesBox);
    return box.values
        .map((m) => Category.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<int> insertCategory(Category category) async {
    final box = Hive.box<Map>(_categoriesBox);
    final meta = Hive.box(_metaBox);
    final id = (meta.get('category_next_id') as int?) ?? 9;
    final map = category.toMap()..['id'] = id;
    await box.put(id, map);
    await meta.put('category_next_id', id + 1);
    return id;
  }

  Future<int> updateCategory(Category category) async {
    final box = Hive.box<Map>(_categoriesBox);
    await box.put(category.id, category.toMap());
    return 1;
  }

  Future<int> deleteCategory(int id) async {
    final box = Hive.box<Map>(_categoriesBox);
    await box.delete(id);
    return 1;
  }

  // ─── USER CONFIG ────────────────────────────────────────────────────────────

  Future<UserConfig> getUserConfig() async {
    final box = Hive.box<Map>(_usersBox);
    final m = box.get(1);
    if (m == null) {
      return UserConfig(
          id: 1, userName: 'المستخدم', dailyLimit: 100.0, currency: 'ر.س');
    }
    return UserConfig.fromMap(Map<String, dynamic>.from(m));
  }

  Future<int> updateUserConfig(UserConfig config) async {
    final box = Hive.box<Map>(_usersBox);
    await box.put(config.id ?? 1, config.toMap());
    return 1;
  }
}
