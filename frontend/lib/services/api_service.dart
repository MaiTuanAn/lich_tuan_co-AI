import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

class ApiService {
  // Nếu chạy Flutter Windows Desktop hoặc Chrome: dùng 127.0.0.1
  // Nếu chạy trên máy ảo Android Emulator: đổi thành http://10.0.2.2:8000/api
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  // 1. Lấy danh sách sự kiện từ server
  Future<List<EventModel>> getEvents() async {
    final response = await http.get(Uri.parse('$baseUrl/events'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((item) => EventModel.fromJson(item)).toList();
    } else {
      throw Exception('Không thể tải lịch từ máy chủ');
    }
  }

  // 2. Tạo sự kiện mới (trả về thông báo lỗi nếu bị trùng giờ)
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
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Lỗi khi tạo sự kiện');
    }
  }

  // 3. Xóa sự kiện
  Future<void> deleteEvent(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/events/$id'));
    if (response.statusCode != 200) {
      throw Exception('Không thể xóa sự kiện');
    }
  }
}