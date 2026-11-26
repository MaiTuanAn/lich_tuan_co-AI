import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_suggestion_model.dart';
import '../models/event_model.dart';

class AiReply {
  final String text;
  final List<AiSuggestion> suggestions;
  AiReply({required this.text, this.suggestions = const []});
}

/// Gọi Edge Function `ai-chat`. Khóa Gemini nằm trên server, app không biết.
/// Quy ước thời gian: gửi và nhận "giờ địa phương" dạng yyyy-MM-ddTHH:mm (không múi giờ).
class AiService {
  static final DateFormat _wire = DateFormat("yyyy-MM-dd'T'HH:mm");

  Future<AiReply> ask({
    required String message,
    required List<EventModel> events,
    required List<String> categories,
    required int defaultDurationMinutes,
    required String style,
  }) async {
    final now = DateTime.now();

    // Chỉ gửi các sự kiện còn liên quan (từ hôm qua tới 60 ngày tới) để payload nhỏ
    final from = now.subtract(const Duration(days: 1));
    final to = now.add(const Duration(days: 60));
    final busy = events
        .where((e) => e.endTime.isAfter(from) && e.startTime.isBefore(to))
        .map((e) => {
              'start': _wire.format(e.startTime),
              'end': _wire.format(e.endTime),
            })
        .toList();

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'ai-chat',
        body: {
          'message': message,
          'now': _wire.format(now),
          'busy': busy,
          'categories': categories,
          'default_duration_minutes': defaultDurationMinutes,
          'style': style,
        },
      );

      final data = res.data;
      if (data is! Map<String, dynamic>) {
        throw Exception('Phản hồi từ trợ lý AI không hợp lệ.');
      }

      final list = (data['suggestions'] as List? ?? const [])
          .map((s) => AiSuggestion.fromJson(s as Map<String, dynamic>))
          .toList();

      return AiReply(text: (data['reply'] as String?) ?? '', suggestions: list);
    } on FunctionException catch (e) {
      final details = e.details;
      final msg = details is Map && details['error'] is String
          ? details['error'] as String
          : 'Không gọi được trợ lý AI (mã ${e.status}).';
      throw Exception(msg);
    }
  }
}
