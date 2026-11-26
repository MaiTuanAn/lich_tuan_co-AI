import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/ai_suggestion_model.dart';
import '../providers/calendar_provider.dart';

class AiChatSidebar extends StatefulWidget {
  const AiChatSidebar({super.key});

  @override
  State<AiChatSidebar> createState() => _AiChatSidebarState();
}

class _AiChatSidebarState extends State<AiChatSidebar> {
  final TextEditingController _controller = TextEditingController();

  void _send(CalendarProvider provider) {
    if (_controller.text.trim().isEmpty) return;
    provider.sendUserChatMessage(_controller.text);
    _controller.clear();
  }

  static const List<String> _weekdays = [
    'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ nhật',
  ];

  String _formatRange(DateTime s, DateTime e) {
    final day = '${_weekdays[s.weekday - 1]}, ${DateFormat('dd/MM').format(s)}';
    final time = DateFormat('HH:mm');
    return '$day · ${time.format(s)} – ${time.format(e)}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final isDark = provider.isDarkMode;

    return Container(
      width: 340,
      margin: const EdgeInsets.only(right: 12, bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        children: [
          // Header AI Assistant + Nút đóng X
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.indigoAccent, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Ẩn khung chat AI',
                  onPressed: provider.toggleChatSidebar,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Danh sách tin nhắn & các gợi ý khung giờ do AI đề xuất
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.chatMessages.length + (provider.isAiThinking ? 1 : 0),
              itemBuilder: (context, index) {
                // Dòng "đang suy nghĩ" ở cuối danh sách
                if (index == provider.chatMessages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Đang tìm khung giờ phù hợp...',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final msg = provider.chatMessages[index];
                final isUser = msg['isUser'] as bool;
                final suggestions =
                    (msg['suggestions'] as List<AiSuggestion>?) ?? const <AiSuggestion>[];

                return Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser
                            ? Colors.indigo.shade600
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        msg['text'] as String,
                        style: TextStyle(
                          color: isUser
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          fontSize: 13.5,
                        ),
                      ),
                    ),

                    // Mỗi khung giờ trống là một thẻ riêng, bấm Schedule để tạo sự kiện thật
                    for (final s in suggestions)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatRange(s.start, s.end),
                              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => provider.acceptAiSuggestion(msg, s),
                              child: const Text('Schedule'),
                            ),
                          ],
                        ),
                      ),

                    if (suggestions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextButton(
                          onPressed: () => provider.dismissAiSuggestions(msg),
                          child: const Text('Cancel'),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Ô nhập lệnh chat
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _send(provider),
              decoration: InputDecoration(
                hintText: 'Ask AI assistant...',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic_none, size: 20),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, size: 20),
                      onPressed: () => _send(provider),
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
