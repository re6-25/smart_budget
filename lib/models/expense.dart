class Expense {
  final int? id;
  final double amount;
  final String date; // YYYY-MM-DD
  final int categoryId;
  final String personName;
  final String? note;
  final String? imagePath;
  final String? currency; // Currency code for this specific expense

  Expense({
    this.id,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.personName,
    this.note,
    this.imagePath,
    this.currency,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date,
      'category_id': categoryId,
      'person_name': personName,
      'note': note,
      'image_path': imagePath,
      'currency': currency,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      date: map['date'],
      categoryId: map['category_id'],
      personName: map['person_name'],
      note: map['note'],
      imagePath: map['image_path'],
      currency: map['currency'],
    );
  }

  Expense copyWith({
    int? id,
    double? amount,
    String? date,
    int? categoryId,
    String? personName,
    String? note,
    String? imagePath,
    String? currency,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      personName: personName ?? this.personName,
      note: note ?? this.note,
      imagePath: imagePath ?? this.imagePath,
      currency: currency ?? this.currency,
    );
  }
}
