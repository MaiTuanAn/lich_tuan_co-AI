import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../widgets/ai_chat_sidebar.dart';
import '../widgets/left_sidebar.dart';
import '../widgets/top_header_bar.dart';
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
    // Tự động tải danh sách lịch từ FastAPI ngay khi mở ứng dụng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalendarProvider>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isChatOpen = context.select<CalendarProvider, bool>((p) => p.isChatSidebarOpen);

    return Scaffold(
      body: Row(
        children: [
          // CỘT 1: Sidebar bên trái (Mini Calendar & Bộ lọc danh mục)
          const LeftSidebar(),

          // CỘT 2: Khu vực trung tâm (Thanh điều hướng + Lưới lịch tuần 7 ngày)
          const Expanded(
            child: Column(
              children: [
                TopHeaderBar(),
                Expanded(child: WeeklyGridView()),
              ],
            ),
          ),

          // CỘT 3: Khung Chatbot AI bên phải (Có thể ẩn/hiện linh hoạt)
          if (isChatOpen) const AiChatSidebar(),
        ],
      ),
    );
  }
}