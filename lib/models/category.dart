import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final int iconCode;
  final String colorHex;

  Category({
    this.id,
    required this.name,
    required this.iconCode,
    required this.colorHex,
  });

  Color get color {
    final hex = colorHex.replaceAll('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code': iconCode,
      'color_hex': colorHex,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      iconCode: map['icon_code'],
      colorHex: map['color_hex'],
    );
  }

  Category copyWith({
    int? id,
    String? name,
    int? iconCode,
    String? colorHex,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
