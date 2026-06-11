import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../providers/settings_provider.dart';
import '../models/expense.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final exp = context.watch<ExpenseProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تصدير التقارير')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نطاق التاريخ', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _dateBox(
                            context,
                            'من',
                            DateFormat('d MMM yyyy', 'ar').format(_dateRange.start),
                            Icons.calendar_today,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_back),
                        ),
                        Expanded(
                          child: _dateBox(
                            context,
                            'إلى',
                            DateFormat('d MMM yyyy', 'ar').format(_dateRange.end),
                            Icons.event,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: _dateRange,
                          locale: const Locale('ar'),
                        );
                        if (range != null) setState(() => _dateRange = range);
                      },
                      icon: const Icon(Icons.date_range),
                      label: const Text('تغيير النطاق'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Presets
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('اختيارات سريعة', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        _presetChip('هذا الأسبوع', 7),
                        _presetChip('هذا الشهر', 30),
                        _presetChip('آخر 3 أشهر', 90),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Export Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generating
                    ? null
                    : () => _generatePdf(context, exp, settings),
                icon: _generating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_generating
                    ? 'جاري الإنشاء...'
                    : 'تصدير كـ PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _printReport(context, exp, settings),
                icon: const Icon(Icons.print),
                label: const Text('طباعة التقرير'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateBox(
      BuildContext context, String label, String date, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(children: [
            Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        ],
      ),
    );
  }

  Widget _presetChip(String label, int days) {
    return ActionChip(
      label: Text(label),
      onPressed: () => setState(() {
        _dateRange = DateTimeRange(
          start: DateTime.now().subtract(Duration(days: days)),
          end: DateTime.now(),
        );
      }),
    );
  }

  Future<void> _generatePdf(BuildContext context, ExpenseProvider exp,
      SettingsProvider settings) async {
    setState(() => _generating = true);

    try {
      final start =
          DateFormat('yyyy-MM-dd').format(_dateRange.start);
      final end = DateFormat('yyyy-MM-dd').format(_dateRange.end);
      final expenses = await exp.getExpensesByDateRange(start, end);
      final total =
          expenses.fold<double>(0, (sum, e) => sum + e.amount);

      final arabicFont = await PdfGoogleFonts.amiriRegular();
      final arabicFontBold = await PdfGoogleFonts.amiriBold();

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('تقرير الميزانية الذكية',
                  style: pw.TextStyle(
                      font: arabicFontBold, fontSize: 22)),
            ),
            pw.Paragraph(
              text:
                  'الفترة: $start إلى $end | العملة الافتراضية: ${settings.currency}',
              style: pw.TextStyle(font: arabicFont),
            ),
            pw.SizedBox(height: 10),
            pw.Text('إجمالي المصاريف: ${total.toStringAsFixed(2)} - يرجى ملاحظة اختلاف العملات أدناه',
                style: pw.TextStyle(
                    font: arabicFontBold, fontSize: 14)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['المبلغ', 'الملاحظة', 'الشخص', 'التاريخ', '#'],
              headerStyle: pw.TextStyle(font: arabicFontBold, color: PdfColors.white),
              cellStyle: pw.TextStyle(font: arabicFont),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              data: expenses.asMap().entries.map((entry) {
                final i = entry.key + 1;
                final e = entry.value;
                return [
                  '${e.amount.toStringAsFixed(2)} ${e.currency ?? settings.currency}',
                  e.note ?? '-',
                  e.personName,
                  e.date,
                  '$i',
                ];
              }).toList(),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'smart_budget_$start-$end.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _printReport(BuildContext context, ExpenseProvider exp,
      SettingsProvider settings) async {
    final start = DateFormat('yyyy-MM-dd').format(_dateRange.start);
    final end = DateFormat('yyyy-MM-dd').format(_dateRange.end);
    final expenses = await exp.getExpensesByDateRange(start, end);
    final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    await Printing.layoutPdf(
      onLayout: (format) async {
        final arabicFont = await PdfGoogleFonts.amiriRegular();
        final arabicFontBold = await PdfGoogleFonts.amiriBold();
        
        final pdf = pw.Document();
        pdf.addPage(pw.Page(
          pageFormat: format,
          textDirection: pw.TextDirection.rtl,
          build: (_) => pw.Column(
            children: [
              pw.Text('الميزانية الذكية',
                  style: pw.TextStyle(
                      font: arabicFontBold, fontSize: 24)),
              pw.SizedBox(height: 8),
              pw.Text('من $start إلى $end', style: pw.TextStyle(font: arabicFont)),
              pw.SizedBox(height: 4),
              pw.Text(
                  'إجمالي المصاريف: ${total.toStringAsFixed(2)}',
                  style: pw.TextStyle(font: arabicFontBold)),
            ],
          ),
        ));
        return pdf.save();
      },
    );
  }
}
