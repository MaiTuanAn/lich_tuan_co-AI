import 'package:flutter/material.dart';

class AppColors {
  // Bảng màu chọn nhanh khi người dùng tạo danh mục mới (Create New Category)
  static const List<Color> categoryPalette = [
    Color(0xFF9333EA), // Tím (Purple)
    Color(0xFF0D9488), // Xanh ngọc (Teal)
    Color(0xFFEC4899), // Hồng (Pink)
    Color(0xFFD97706), // Cam vàng (Amber)
    Color(0xFF2563EB), // Xanh dương (Blue)
    Color(0xFF06B6D4), // Xanh lơ (Cyan)
    Color(0xFF65A30D), // Xanh chanh (Lime)
    Color(0xFFDC2626), // Đỏ (Red)
  ];

  // Lấy màu nền thẻ sự kiện tùy theo Light Mode hay Dark Mode
  static Color getEventBackground(Color baseColor, bool isDark) {
    if (isDark) {
      return baseColor.withValues(alpha: 0.85); // Màu dạ quang nổi bật trên nền tối
    }
    return Color.alphaBlend(baseColor.withValues(alpha: 0.18), Colors.white); // Pastel dịu mắt
  }

  static Color getEventTextColor(Color baseColor, bool isDark) {
    return isDark ? Colors.white : baseColor;
  }
}
