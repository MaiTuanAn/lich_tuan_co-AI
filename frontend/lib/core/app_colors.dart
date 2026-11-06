import 'package:flutter/material.dart';

class AppColors {
  // Màu nền tổng thể
  static const Color appBackground = Color(0xFFF8FAFC);
  static const Color sidebarBackground = Color(0xFFF1F5F9);
  static const Color cardBackground = Colors.white;
  static const Color borderColor = Color(0xFFE2E8F0);

  // Màu chữ
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);

  // Danh sách các danh mục chuẩn
  static const List<String> categories = [
    'Công việc',
    'Học tập',
    'Cá nhân',
    'Khẩn cấp',
  ];

  // Màu nền Pastel cho khối sự kiện trên lịch
  static Color getCategoryPastelColor(String category) {
    switch (category) {
      case 'Học tập':
        return const Color(0xFFDCFCE7); // Xanh lá pastel
      case 'Cá nhân':
        return const Color(0xFFFFEDD5); // Cam pastel
      case 'Khẩn cấp':
        return const Color(0xFFFEE2E2); // Đỏ pastel
      case 'Công việc':
      default:
        return const Color(0xFFDBEAFE); // Xanh dương pastel
    }
  }

  // Màu đậm cho chấm tròn bộ lọc và chữ tiêu đề sự kiện
  static Color getCategoryPrimaryColor(String category) {
    switch (category) {
      case 'Học tập':
        return const Color(0xFF16A34A); // Xanh lá đậm
      case 'Cá nhân':
        return const Color(0xFFEA580C); // Cam đậm
      case 'Khẩn cấp':
        return const Color(0xFFDC2626); // Đỏ đậm
      case 'Công việc':
      default:
        return const Color(0xFF2563EB); // Xanh dương đậm
    }
  }
}