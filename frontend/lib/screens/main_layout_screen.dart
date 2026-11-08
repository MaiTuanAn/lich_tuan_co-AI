import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../widgets/ai_chat_sidebar.dart';
import '../widgets/top_header_bar.dart';
import '../widgets/vertical_taskbar.dart';
import '../widgets/weekly_grid_view.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarProvider>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final isDark = provider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Row(
        children: [
          // 1. Thanh Taskbar dọc 68px bên trái
          const VerticalTaskbar(),

          // 2. Khu vực chính: Header ở trên + Lịch tuần & Khung Chat AI ở dưới
          Expanded(
            child: Column(
              children: [
                const TopHeaderBar(),
                Expanded(
                  child: Row(
                    children: [
                      // Bảng Lịch tuần tự động co giãn (Expanded) để lấp đầy khoảng trống
                      const Expanded(
                        child: WeeklyGridView(),
                      ),

                      // Khung Chatbot AI chỉ xuất hiện khi Đã Đăng nhập VÀ đang bật icon AI
                      if (provider.isChatSidebarOpen)
                        const AiChatSidebar(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}