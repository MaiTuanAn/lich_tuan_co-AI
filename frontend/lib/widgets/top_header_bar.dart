import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import 'auth_account_dialogs.dart';

class TopHeaderBar extends StatelessWidget {
  const TopHeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final isDark = provider.isDarkMode;
    final monthTitle = DateFormat('MMMM yyyy').format(provider.focusedDate);

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      ),
      child: Row(
        children: [
          // 1. Tiêu đề Tháng Năm & Mũi tên chuyển tuần (< >)
          Text(
            monthTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            tooltip: 'Tuần trước',
            onPressed: provider.goToPreviousWeek,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22),
            tooltip: 'Tuần sau',
            onPressed: provider.goToNextWeek,
          ),

          const Spacer(),

          // 2. NẾU ĐÃ ĐĂNG NHẬP: Hiện huy hiệu trạng thái đồng bộ Cloud ở giữa
          if (provider.isLoggedIn) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sync, size: 15, color: isDark ? Colors.tealAccent : Colors.teal.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Syncing with cloud',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],

          // 3. GÓC TRÊN BÊN PHẢI: Nếu chưa đăng nhập -> Hiện 2 nút xếp ngang [Đăng nhập] [✔ Khách]
          if (!provider.isLoggedIn)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nút Đăng nhập
                FilledButton.tonal(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const LoginRegisterDialog(initialIsLogin: true),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFBFDBFE),
                    foregroundColor: const Color(0xFF1E3A8A),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text('Đăng nhập', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),

                // Nút Chế độ Khách (Đang kích hoạt)
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Đang dùng Chế độ Khách (Dữ liệu lưu trên máy này)',
                          textAlign: TextAlign.center,
                        ),
                        behavior: SnackBarBehavior.floating,
                        width: 420,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                  label: const Text('Khách'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFF60A5FA), width: 1.5),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFDBEAFE).withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
