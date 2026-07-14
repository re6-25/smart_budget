import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final List<IconData> _availableIcons = [
    Icons.fastfood, Icons.directions_car, Icons.receipt, Icons.local_hospital,
    Icons.movie, Icons.shopping_bag, Icons.school, Icons.home,
    Icons.sports_soccer, Icons.flight, Icons.pets, Icons.wifi,
    Icons.phone_android, Icons.fitness_center, Icons.calculate, Icons.beach_access,
  ];

  final List<Color> _availableColors = [
    const Color(0xFFFF6B6B), const Color(0xFF4ECDC4), const Color(0xFFFFE66D),
    const Color(0xFFA8E6CF), const Color(0xFFDDA0DD), const Color(0xFF85C1E9),
    const Color(0xFFF7DC6F), const Color(0xFFAED6F1), const Color(0xFFFF6B35),
    const Color(0xFF00D4AA), const Color(0xFFFF4757), const Color(0xFF7BED9F),
  ];

  @override
  Widget build(BuildContext context) {
    final catProvider = context.watch<CategoryProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الفئات')),
      body: catProvider.categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('لا توجد فئات بعد',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: catProvider.categories.length,
              itemBuilder: (ctx, i) {
                final cat = catProvider.categories[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: cat.color.withOpacity(0.2),
                      child: Icon(cat.icon, color: cat.color),
                    ),
                    title: Text(cat.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () =>
                              _showCategorySheet(context, existing: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _confirmDelete(context, catProvider, cat),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategorySheet(context),
        icon: const Icon(Icons.add),
        label: const Text('فئة جديدة'),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, CategoryProvider provider, Category cat) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الفئة'),
        content: Text('هل تريد حذف فئة "${cat.name}"؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final deleted = await provider.deleteCategory(cat.id!);
              if (!context.mounted) return;

              if (!deleted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'لا يمكن حذف الفئة لأنها مرتبطة بمصروفات'),
                  ),
                );
                return;
              }

              await context.read<ExpenseProvider>().loadAll();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCategorySheet(BuildContext context, {Category? existing}) {
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    IconData selectedIcon =
        existing != null ? existing.icon : _availableIcons.first;
    Color selectedColor =
        existing != null ? existing.color : _availableColors.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                existing != null ? 'تعديل فئة' : 'فئة جديدة',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم الفئة',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),
              const Text('الأيقونة',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableIcons.length,
                  itemBuilder: (_, i) {
                    final icon = _availableIcons[i];
                    final sel = selectedIcon == icon;
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedIcon = icon),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: sel
                              ? selectedColor.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel ? selectedColor : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(icon,
                            color: sel ? selectedColor : Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Text('اللون',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  itemBuilder: (_, i) {
                    final color = _availableColors[i];
                    final sel = selectedColor == color;
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedColor = color),
                      child: Container(
                        margin: const EdgeInsets.only(left: 8),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: sel ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: sel
                              ? [BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8)]
                              : [],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    final hex = selectedColor.value
                        .toRadixString(16)
                        .substring(2)
                        .toUpperCase();
                    final cat = Category(
                      id: existing?.id,
                      name: nameController.text,
                      iconCode: selectedIcon.codePoint,
                      colorHex: hex,
                    );

                    final provider =
                        context.read<CategoryProvider>();
                    if (existing != null) {
                      await provider.updateCategory(cat);
                    } else {
                      await provider.addCategory(cat);
                    }
                    await context.read<ExpenseProvider>().loadAll();
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(existing != null ? 'حفظ التعديل' : 'إضافة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
