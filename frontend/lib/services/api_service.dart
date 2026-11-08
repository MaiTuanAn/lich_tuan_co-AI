import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/event_model.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  String? _accessToken;

  void setToken(String? token) {
    _accessToken = token;
  }

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    if (_accessToken != null && _accessToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // Xử lý thông báo lỗi trả về từ FastAPI hoặc Pydantic Validation
  String _extractErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body['detail'] is String) {
        return body['detail'];
      } else if (body['detail'] is List && body['detail'].isNotEmpty) {
        return body['detail'][0]['msg'].toString().replaceAll('Value error, ', '');
      }
    } catch (_) {}
    return 'Có lỗi xảy ra (Mã: ${response.statusCode})';
  }

  // 1. ĐĂNG KÝ TÀI KHOẢN MỚI
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  // 2. ĐĂNG NHẬP TÀI KHOẢN
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  // 3. ĐỔI MẬT KHẨU
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _headers,
      body: jsonEncode({
        'old_password': oldPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  // 4. LẤY DANH SÁCH LỊCH TUẦN (Tự động lọc theo Token User hoặc Khách)
  Future<List<EventModel>> fetchEvents() async {
    final response = await http.get(Uri.parse('$baseUrl/events'), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => EventModel.fromJson(json)).toList();
    } else {
      throw Exception(_extractErrorMessage(response));
    }
  }

  // 5. TẠO SỰ KIỆN MỚI
  Future<EventModel> createEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String category,
    String description = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/events'),
      headers: _headers,
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
      throw Exception(_extractErrorMessage(response));
    }
  }

  // 6. SỬA SỰ KIỆN
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
      headers: _headers,
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
      throw Exception(_extractErrorMessage(response));
    }
  }

  // 7. XÓA SỰ KIỆN
  Future<void> deleteEvent(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/events/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response));
    }
  }
}
