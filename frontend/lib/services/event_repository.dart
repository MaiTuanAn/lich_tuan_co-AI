import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';

/// CRUD sự kiện. RLS trên server đảm bảo mỗi user chỉ thấy lịch của mình,
/// nên không cần lọc user_id ở đây.
class EventRepository {
  SupabaseClient get _db => Supabase.instance.client;

  // Lấy luôn tên danh mục qua khóa ngoại category_id
  static const String _select = '*, categories(name)';

  Future<List<EventModel>> fetchAll() async {
    try {
      final rows = await _db
          .from('events')
          .select(_select)
          .order('start_time', ascending: true);
      return rows.map((r) => EventModel.fromJson(r)).toList();
    } on PostgrestException catch (e) {
      throw _toException(e);
    }
  }

  Future<EventModel> create({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String? categoryId,
    String description = '',
  }) async {
    try {
      final row = await _db
          .from('events')
          .insert({
            'title': title.trim(),
            'start_time': startTime.toUtc().toIso8601String(),
            'end_time': endTime.toUtc().toIso8601String(),
            'category_id': categoryId,
            'description': description,
          })
          .select(_select)
          .single();
      return EventModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw _toException(e);
    }
  }

  Future<EventModel> update({
    required String id,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String? categoryId,
    String description = '',
  }) async {
    try {
      final row = await _db
          .from('events')
          .update({
            'title': title.trim(),
            'start_time': startTime.toUtc().toIso8601String(),
            'end_time': endTime.toUtc().toIso8601String(),
            'category_id': categoryId,
            'description': description,
          })
          .eq('id', id)
          .select(_select)
          .single();
      return EventModel.fromJson(row);
    } on PostgrestException catch (e) {
      throw _toException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _db.from('events').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw _toException(e);
    }
  }

  Exception _toException(PostgrestException e) {
    switch (e.code) {
      case '23P01': // exclusion_violation: trùng giờ với sự kiện khác
        return Exception('Trùng lịch với một sự kiện khác của bạn!');
      case '23514': // check_violation: end_time <= start_time
        return Exception('Thời gian kết thúc phải lớn hơn thời gian bắt đầu!');
      case 'PGRST116': // không có dòng nào khớp
        return Exception('Không tìm thấy sự kiện!');
      default:
        return Exception(e.message);
    }
  }
}
