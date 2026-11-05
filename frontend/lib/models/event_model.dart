import 'package:flutter/material.dart';

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

  // Chuyển chuỗi JSON từ Python FastAPI thành đối tượng trong Dart
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

  // Chuyển đối tượng Dart thành JSON để gửi lên Python
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'category': category,
      'description': description,
    };
  }

  // Tự động gán màu sắc hiển thị theo danh mục
  Color get color {
    switch (category) {
      case 'Học tập':
        return Colors.green.shade600;
      case 'Cá nhân':
        return Colors.orange.shade600;
      case 'Khẩn cấp':
        return Colors.red.shade600;
      case 'Công việc':
      default:
        return Colors.blue.shade600;
    }
  }
}