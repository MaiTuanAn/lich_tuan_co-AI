import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class EventModel {
  final int id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String category;
  final String description;

  EventModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.description = '',
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      category: json['category'] ?? 'Công việc',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'category': category,
      'description': description,
    };
  }

  Color get backgroundColor => AppColors.getCategoryPastelColor(category);
  Color get primaryColor => AppColors.getCategoryPrimaryColor(category);
}