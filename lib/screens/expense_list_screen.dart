import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';
import 'add_expense_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  String _searchQuery = '';
  int? _filterCategoryId;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final exp = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    List<Expense> filtered = exp.expenses;

    if (_filterCategoryId != null) {
      filtered = filtered.where((e) => e.categoryId == _filterCategoryId).toList();
    }

    if (_dateRange != null) {
      final start = DateFormat('yyyy-MM-dd').format(_dateRange!.start);
      final end = DateFormat('yyyy-MM-dd').format(_dateRange!.end);
      filtered = filtered.where((e) => e.date.compareTo(start) >= 0 && e.date.compareTo(end) <= 0).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((e) {
        final cat = exp.getCategoryById(e.categoryId);
        return (cat?.name ?? '').contains(_searchQuery) ||
            (e.note ?? '').contains(_searchQuery) ||
            e.personName.contains(_searchQuery);
      }).toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل المصاريف'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context, exp),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'بحث في المصاريف...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''))
                    : null,
              ),
            ),
          ),
          if (_filterCategoryId != null || _dateRange != null)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (_filterCategoryId != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Chip(
                        label: Text(exp.getCategoryById(_filterCategoryId!)?.name ?? ''),
                        onDeleted: () => setState(() => _filterCategoryId = null),
                      ),
                    ),
                  if (_dateRange != null)
                    Chip(
                      label: Text(
                          '${DateFormat('d/M').format(_dateRange!.start)} - ${DateFormat('d/M').format(_dateRange!.end)}'),
                      onDeleted: () => setState(() => _dateRange = null),
                    ),
                ],
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text('لا توجد مصاريف',
                            style: TextStyle(color: Colors.grey, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final expense = filtered[i];
                      final category =
                          exp.getCategoryById(expense.categoryId);
                      return Slidable(
                        key: ValueKey(expense.id),
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddExpenseScreen(
                                      existingExpense: expense),
                                ),
                              ),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              icon: Icons.edit,
                              label: 'تعديل',
                            ),
                          ],
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _confirmDelete(context, exp, expense),
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'حذف',
                            ),
                          ],
                        ),
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  (category?.color ?? Colors.grey)
                                      .withOpacity(0.2),
                              child: Icon(
                                category?.icon ?? Icons.money,
                                color: category?.color ?? Colors.grey,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(category?.name ?? 'أخرى',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                if (expense.imagePath != null)
                                  GestureDetector(
                                    onTap: () => _viewImage(
                                        context, expense.imagePath!),
                                    child: const Icon(Icons.image,
                                        size: 16, color: Colors.blue),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              '${expense.personName} • ${expense.date}${expense.note != null ? ' • ${expense.note}' : ''}',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              '${expense.amount.toStringAsFixed(2)} ${expense.currency ?? settings.currency}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _viewImage(BuildContext context, String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('صورة الفاتورة',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 300,
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, ExpenseProvider provider, Expense expense) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف المصروف'),
        content: const Text('هل أنت متأكد من حذف هذا المصروف؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteExpense(expense.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, ExpenseProvider exp) {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('تصفية المصاريف',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('الفئة'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: exp.categories.map((cat) {
                  final selected = _filterCategoryId == cat.id;
                  return FilterChip(
                    selected: selected,
                    label: Text(cat.name),
                    avatar: Icon(cat.icon, color: cat.color, size: 16),
                    onSelected: (_) {
                      setSheetState(() => _filterCategoryId =
                          selected ? null : cat.id);
                      setState(() =>
                          _filterCategoryId = selected ? null : cat.id);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: const Locale('ar'),
                  );
                  if (range != null) {
                    setState(() => _dateRange = range);
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.date_range),
                label: const Text('اختيار نطاق تاريخ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
