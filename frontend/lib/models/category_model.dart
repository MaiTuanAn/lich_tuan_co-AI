import 'package:flutter/material.dart';

class CategoryModel {
  final String name;
  final Color color;
  bool isVisible;

  CategoryModel({
    required this.name,
    required this.color,
    this.isVisible = true,
  });
}