import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../providers/calendar_provider.dart';

class AiChatSidebar extends StatefulWidget {
  const AiChatSidebar({super.key});

  @override
  State<AiChatSidebar> createState() => _AiChatSidebarState();
}

class _AiChatSidebarState extends State<AiChatSidebar> {
  final TextEditingController _chatController = TextEditingController();

  void _handleSend(CalendarProvider provider) {
    if (_chatController.text.trim().isEmpty) return;
    provider.sendUserChatMessage(_chatController.text);
    _chatController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();

    return Container(
      width: 330,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppColors.borderColor)),
      ),
      child: Column(
        children: [
          // 1. Tiêu đề AI Scheduler
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderColor)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.indigo.shade600, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'AI Scheduler',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // 2. Danh sách hội thoại
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.chatMessages.length,
              itemBuilder: (context, index) {
                final msg = provider.chatMessages[index];
                final isUser = msg['isUser'] as bool;

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 260),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.indigo.shade600 : AppColors.sidebarBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text'] as String,
                      style: TextStyle(
                        color: isUser ? Colors.white : AppColors.textPrimary,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Ô nhập câu lệnh tiếng Việt tự nhiên
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    onSubmitted: (_) => _handleSend(provider),
                    decoration: InputDecoration(
                      hintText: 'Nhập lệnh tạo lịch...',
                      hintStyle: const TextStyle(fontSize: 13),
                      filled: true,
                      fillColor: AppColors.sidebarBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _handleSend(provider),
                  icon: Icon(Icons.send_rounded, color: Colors.indigo.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}