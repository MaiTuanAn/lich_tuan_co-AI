import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/calendar_provider.dart';
import 'event_form_dialog.dart';

class LeftSidebar extends StatelessWidget {
  const LeftSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBackground,
        border: Border(right: BorderSide(color: AppColors.borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Logo & Tên ứng dụng
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 10),
                const Text(
                  'SchedulAI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // 2. Nút "+ Create" tạo sự kiện nhanh
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const EventFormDialog(),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text(
                  'Create Event',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. Mini Month Calendar (Chọn nhanh ngày trong tháng)
          SizedBox(
            height: 250,
            child: CalendarDatePicker(
              initialDate: provider.focusedDate,
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
              onDateChanged: (pickedDate) {
                provider.selectSpecificDate(pickedDate);
              },
            ),
          ),

          const Divider(color: AppColors.borderColor, height: 24),

          // 4. Bộ lọc Danh mục (My Calendars)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text(
              'MY CALENDARS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: AppColors.categories.map((category) {
                final isSelected = provider.selectedCategories.contains(category);
                final color = AppColors.getCategoryPrimaryColor(category);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (_) => provider.toggleCategory(category),
                  dense: true,
                  activeColor: color,
                  controlAffinity: ListTileControlAffinity.trailing,
                  secondary: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}