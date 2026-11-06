import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../core/app_colors.dart';
import '../providers/calendar_provider.dart';

class TopHeaderBar extends StatelessWidget {
  const TopHeaderBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final dateTitle = DateFormat('MMMM yyyy').format(provider.focusedDate);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderColor)),
      ),
      child: Row(
        children: [
          // Nút Today
          OutlinedButton(
            onPressed: provider.goToToday,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.borderColor),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Today', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),

          // Mũi tên chuyển tuần Trước / Sau
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Tuần trước',
            onPressed: provider.goToPrevious,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Tuần sau',
            onPressed: provider.goToNext,
          ),
          const SizedBox(width: 12),

          // Hiển thị Tháng Năm hiện tại
          Text(
            dateTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const Spacer(),

          // Bộ chuyển đổi chế độ xem: Day | Week | Month
          SegmentedButton<CalendarView>(
            segments: const [
              ButtonSegment(value: CalendarView.day, label: Text('Day')),
              ButtonSegment(value: CalendarView.week, label: Text('Week')),
              ButtonSegment(value: CalendarView.month, label: Text('Month')),
            ],
            selected: {provider.currentView},
            onSelectionChanged: (Set<CalendarView> newSelection) {
              provider.setCalendarView(newSelection.first);
            },
          ),
          const SizedBox(width: 16),

          // Nút Làm mới dữ liệu từ Server
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại lịch từ Server',
            onPressed: provider.loadEvents,
          ),

          // Nút Ẩn / Hiện cột Chatbot AI bên phải
          IconButton(
            icon: Icon(
              provider.isChatSidebarOpen ? Icons.auto_awesome : Icons.auto_awesome_outlined,
              color: Colors.indigo,
            ),
            tooltip: 'Đóng/Mở AI Scheduler',
            onPressed: provider.toggleChatSidebar,
          ),
        ],
      ),
    );
  }
}