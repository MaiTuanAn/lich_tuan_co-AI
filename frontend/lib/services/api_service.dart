import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // 1. Lấy tất cả sự kiện
  Future<List<EventModel>> fetchEvents() async {
    final response = await http.get(Uri.parse('$baseUrl/events'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => EventModel.fromJson(json)).toList();
    } else {
      throw Exception('Không thể tải dữ liệu từ máy chủ FastAPI');
    }
  }

  // 2. Tạo sự kiện mới
  Future<EventModel> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String category,
    String description = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'title': title,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'category': category,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      return EventModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['detail'] ?? 'Lỗi tạo sự kiện');
    }
  }

  // 3. Cập nhật / Sửa sự kiện
  Future<EventModel> updateEvent({
    required int id,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String category,
    String description = '',
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/events/$id'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'title': title,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'category': category,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      return EventModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['detail'] ?? 'Lỗi cập nhật sự kiện');
    }
  }

  // 4. Xóa sự kiện
  Future<void> deleteEvent(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/events/$id'));
    if (response.statusCode != 200) {
      throw Exception('Không thể xóa sự kiện #$id');
    }
  }
}