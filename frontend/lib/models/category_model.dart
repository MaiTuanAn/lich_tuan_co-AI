import 'package:flutter/material.dart';

class CategoryModel {
  final String id; // uuid từ Supabase
  final String name;
  final Color color;
  bool isVisible;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    this.isVisible = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      color: hexToColor(json['color'] as String? ?? '#9333EA'),
      isVisible: json['is_visible'] as bool? ?? true,
    );
  }

  /// '#RRGGBB' -> Color
  static Color hexToColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }

  /// Color -> '#RRGGBB'
  static String colorToHex(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
