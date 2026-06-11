class Badge {
  final String id;
  final String title;
  final String description;
  final int iconCode;
  final DateTime? earnedDate;

  Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconCode,
    this.earnedDate,
  });e

  bool get isEarned => earnedDate != null;
}

final List<Badge> allBadges = [
  Badge(
    id: 'financial_guardian',
    title: 'الحارس المالي',
    description: 'التزمت بميزانيتك اليومية لمدة 7 أيام متتالية',
    iconCode: 0xe30e, // shield
  ),
  Badge(
    id: 'first_expense',
    title: 'أول خطوة',
    description: 'سجّلت أول مصروف لك',
    iconCode: 0xe153, // flag
  ),
  Badge(
    id: 'week_saver',
    title: 'مدّخر الأسبوع',
    description: 'وفّرت أكثر من 50% من ميزانيتك هذا الأسبوع',
    iconCode: 0xe279, // savings
  ),
];
