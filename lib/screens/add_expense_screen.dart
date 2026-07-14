import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../widgets/numeric_keypad.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? existingExpense;
  const AddExpenseScreen({super.key, this.existingExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _amountStr = '0';
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  final _personController = TextEditingController();
  final _noteController = TextEditingController();
  String? _imagePath;
  String? _selectedCurrency;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _amountStr = e.amount.toString();
      _selectedDate = DateTime.parse(e.date);
      _personController.text = e.personName;
      _noteController.text = e.note ?? '';
      _imagePath = e.imagePath;
      _selectedCurrency = e.currency;
    }
  }

  @override
  void dispose() {
    _personController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amountStr.length > 1) {
          _amountStr = _amountStr.substring(0, _amountStr.length - 1);
        } else {
          _amountStr = '0';
        }
      } else if (key == '.') {
        if (!_amountStr.contains('.')) _amountStr += '.';
      } else {
        if (_amountStr == '0') {
          _amountStr = key;
        } else {
          if (_amountStr.contains('.')) {
            final parts = _amountStr.split('.');
            if (parts[1].length < 2) _amountStr += key;
          } else {
            _amountStr += key;
          }
        }
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.camera);
    if (result != null) setState(() => _imagePath = result.path);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('ar'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountStr) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى اختيار الفئة')));
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<ExpenseProvider>();
    final expense = Expense(
      id: widget.existingExpense?.id,
      amount: amount,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      categoryId: _selectedCategory!.id!,
      personName: _personController.text.isEmpty
          ? 'أنا'
          : _personController.text,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      imagePath: _imagePath,
      currency: _selectedCurrency,
    );

    if (widget.existingExpense != null) {
      await provider.updateExpense(expense);
    } else {
      await provider.addExpense(expense);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final exp = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    if (_selectedCategory == null && exp.categories.isNotEmpty) {
      _selectedCategory = widget.existingExpense != null
          ? exp.getCategoryById(widget.existingExpense!.categoryId)
          : exp.categories.first;
    }

    _selectedCurrency ??= settings.currency;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingExpense != null
            ? 'تعديل المصروف'
            : 'إضافة مصروف'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _save,
              tooltip: 'حفظ',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Amount Display
            Container(
              padding: const EdgeInsets.all(24),
              color: theme.colorScheme.surface,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _amountStr,
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showCurrencyPicker(context, settings),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(_selectedCurrency!,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              )),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Numeric Keypad
            NumericKeypad(onKeyPress: _onKeyPress),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Selector
                  Text('الفئة', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: exp.categories.length,
                      itemBuilder: (ctx, i) {
                        final cat = exp.categories[i];
                        final selected = _selectedCategory?.id == cat.id;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected
                                  ? cat.color
                                  : cat.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: cat.color,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(cat.icon,
                                    color: selected
                                        ? Colors.white
                                        : cat.color,
                                    size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    color: selected ? Colors.white : cat.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Date
                  Text('التاريخ', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE، d MMMM yyyy', 'ar')
                                .format(_selectedDate),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Person Name
                  TextField(
                    controller: _personController,
                    decoration: const InputDecoration(
                      labelText: 'اسم الشخص (اختياري)',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Note
                  TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظة (اختياري)',
                      prefixIcon: Icon(Icons.note),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  // Invoice Photo
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(_imagePath == null
                              ? 'التقاط فاتورة'
                              : 'تغيير الصورة'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ),
                      if (_imagePath != null) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              child: Image.file(File(_imagePath!)),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_imagePath!),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save),
                      label: Text(_saving ? 'جاري الحفظ...' : 'حفظ المصروف'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('اختر العملة', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: settings.currencies.length,
                  itemBuilder: (context, index) {
                    final curr = settings.currencies[index];
                    return ListTile(
                      title: Text('${curr['name']} (${curr['symbol']})'),
                      trailing: _selectedCurrency == curr['symbol']
                          ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                          : null,
                      onTap: () {
                        setState(() => _selectedCurrency = curr['symbol']);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
