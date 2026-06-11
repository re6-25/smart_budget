import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/expense.dart';
import '../models/category.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<Expense> _expenses = [];
  List<Category> _categories = [];
  double _dailyTotal = 0.0;
  double _monthlyTotal = 0.0;
  double _dailyLimit = 100.0;
  Map<int, double> _categoryBreakdown = {};
  List<Map<String, dynamic>> _dailyChart = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  List<Category> get categories => _categories;
  double get dailyTotal => _dailyTotal;
  double get monthlyTotal => _monthlyTotal;
  double get dailyLimit => _dailyLimit;
  double get remainingBudget => (_dailyLimit - _dailyTotal).clamp(0, double.infinity);
  double get percentUsed => _dailyLimit > 0 ? (_dailyTotal / _dailyLimit).clamp(0.0, 1.0) : 0.0;
  Map<int, double> get categoryBreakdown => _categoryBreakdown;
  List<Map<String, dynamic>> get dailyChart => _dailyChart;
  bool get isLoading => _isLoading;

  String get today => DateFormat('yyyy-MM-dd').format(DateTime.now());
  String get thisMonth => DateFormat('yyyy-MM').format(DateTime.now());

  Future<void> loadAll({double? dailyLimit}) async {
    _isLoading = true;
    notifyListeners();

    if (dailyLimit != null) _dailyLimit = dailyLimit;

    _expenses = await _db.getAllExpenses();
    _categories = await _db.getAllCategories();
    _dailyTotal = await _db.getDailyTotal(today);
    _monthlyTotal = await _db.getMonthlyTotal(thisMonth);

    final now = DateTime.now();
    final firstDay = DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
    _categoryBreakdown = await _db.getCategoryBreakdown(firstDay, today);
    _dailyChart = await _db.getDailyTotalsForMonth(thisMonth);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _db.insertExpense(expense);
    await loadAll(dailyLimit: _dailyLimit);
  }

  Future<void> updateExpense(Expense expense) async {
    await _db.updateExpense(expense);
    await loadAll(dailyLimit: _dailyLimit);
  }

  Future<void> deleteExpense(int id) async {
    await _db.deleteExpense(id);
    await loadAll(dailyLimit: _dailyLimit);
  }

  Future<List<Expense>> getExpensesByDateRange(String start, String end) async {
    return await _db.getExpensesByDateRange(start, end);
  }

  Category? getCategoryById(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void setDailyLimit(double limit) {
    _dailyLimit = limit;
    notifyListeners();
  }
}
