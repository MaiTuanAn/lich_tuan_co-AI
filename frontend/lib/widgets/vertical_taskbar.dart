import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import 'auth_account_dialogs.dart';
import 'event_form_dialog.dart';
import 'settings_modal.dart';

class VerticalTaskbar extends StatelessWidget {
  const VerticalTaskbar({super.key});

  // Hiển thị Popover Lịch tháng Mini ngay cạnh icon trên cùng
  void _showMiniCalendarPopover(BuildContext context, CalendarProvider provider) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        final isDark = provider.isDarkMode;
        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 76, top: 20),
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(16),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 260,
                      child: CalendarDatePicker(
                        initialDate: provider.focusedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                        onDateChanged: (date) {
                          provider.jumpToDate(date);
                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          provider.goToToday();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Go to Today', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Hiển thị Popover Bộ lọc Danh mục (Categories & Calendars) ngay dưới nút +
  void _showCategoriesFilterPopover(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) {
        return Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 76, top: 140),
            child: Consumer<CalendarProvider>(
              builder: (context, provider, _) {
                final isDark = provider.isDarkMode;
                return Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(16),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Categories & Calendars',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: provider.selectAllCategories,
                              child: const Text(
                                'Select All',
                                style: TextStyle(
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pop(ctx);
                                showDialog(
                                  context: context,
                                  builder: (_) => const CreateCategoryDialog(),
                                );
                              },
                              child: const Text(
                                'Add New Category (+)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...provider.categories.map((cat) {
                          final count = provider.countEventsByCategory(cat.name);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Switch(
                                  value: cat.isVisible,
                                  activeThumbColor: Colors.white,
                                  activeTrackColor: cat.color,
                                  onChanged: (_) => provider.toggleCategoryVisibility(cat.name),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cat.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        '$count events',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.white54 : Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final isDark = provider.isDarkMode;

    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0).withValues(alpha: 0.55),
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFCBD5E1),
          ),
        ),
      ),
      child: Column(
        children: [
          // 1. Icon Lịch tháng trên cùng (Mini Calendar Popover)
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, size: 22),
            tooltip: 'Chọn ngày tháng nhanh',
            onPressed: () => _showMiniCalendarPopover(context, provider),
          ),
          const SizedBox(height: 14),

          // 2. Nút dấu + Tạo sự kiện mới
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => const EventFormDialog(),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                size: 26,
                color: isDark ? Colors.white : const Color(0xFF1E3A8A),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Icon Bộ lọc Danh mục (Luôn có ở cả Chế độ Khách & Đã đăng nhập)
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 24),
            tooltip: 'Bộ lọc Danh mục & Nhãn màu',
            onPressed: () => _showCategoriesFilterPopover(context),
          ),
          const SizedBox(height: 12),

          // 4. Icon Trợ lý AI (CHỈ HIỂN THỊ KHI ĐÃ ĐĂNG NHẬP)
          if (provider.isLoggedIn)
            InkWell(
              onTap: provider.toggleChatSidebar,
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: provider.isChatSidebarOpen
                      ? const Color(0xFFC7D2FE)
                      : Colors.transparent,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  size: 22,
                  color: provider.isChatSidebarOpen
                      ? const Color(0xFF3730A3)
                      : (isDark ? Colors.white70 : const Color(0xFF334155)),
                ),
              ),
            ),

          const Spacer(),

          // 5. Icon Ảnh đại diện User (CHỈ HIỂN THỊ KHI ĐÃ ĐĂNG NHẬP, NẰM TRÊN SETTINGS)
          if (provider.isLoggedIn) ...[
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => const AccountProfileDialog(),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.indigo.shade600,
                child: Text(
                  provider.userName.isNotEmpty ? provider.userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 6. Icon Cài đặt (Settings) ở dưới cùng
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 24),
            tooltip: 'Cài đặt hệ thống',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const SettingsModal(),
              );
            },
          ),
        ],
      ),
    );
  }
}
