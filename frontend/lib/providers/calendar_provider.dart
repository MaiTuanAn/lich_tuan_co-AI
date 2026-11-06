import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../core/app_colors.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';

class CalendarProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final CalendarController calendarController = CalendarController();

  List<EventModel> _allEvents = [];
  Set<String> _selectedCategories = Set.from(AppColors.categories);
  DateTime _focusedDate = DateTime.now();
  CalendarView _currentView = CalendarView.week;
  bool _isLoading = false;
  bool _isChatSidebarOpen = true;

  // Danh sách tin nhắn mẫu cho khung AI Scheduler
  final List<Map<String, dynamic>> chatMessages = [
    {
      'isUser': false,
      'text': 'Xin chào! Tôi là Trợ lý Lịch tuần AI. Bạn có thể bấm "+ Create" hoặc gõ yêu cầu lên lịch tại đây.',
    },
  ];

  // Getters
  bool get isLoading => _isLoading;
  DateTime get focusedDate => _focusedDate;
  CalendarView get currentView => _currentView;
  bool get isChatSidebarOpen => _isChatSidebarOpen;
  Set<String> get selectedCategories => _selectedCategories;

  // Chỉ trả về các sự kiện thuộc danh mục đang được tích chọn ở cột trái
  List<EventModel> get filteredEvents {
    return _allEvents
        .where((e) => _selectedCategories.contains(e.category))
        .toList();
  }

  // Tải danh sách sự kiện từ Backend
  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allEvents = await _apiService.fetchEvents();
    } catch (e) {
      debugPrint('Lỗi tải lịch: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Bật / Tắt bộ lọc danh mục ở Cột Trái
  void toggleCategory(String category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    notifyListeners();
  }

  // Chuyển đổi chế độ xem (Day / Week / Month)
  void setCalendarView(CalendarView view) {
    _currentView = view;
    calendarController.view = view;
    notifyListeners();
  }

  // Điều hướng ngày/tuần
  void goToToday() {
    _focusedDate = DateTime.now();
    calendarController.displayDate = _focusedDate;
    notifyListeners();
  }

  void goToPrevious() {
    calendarController.backward!();
    _focusedDate = calendarController.displayDate ?? DateTime.now();
    notifyListeners();
  }

  void goToNext() {
    calendarController.forward!();
    _focusedDate = calendarController.displayDate ?? DateTime.now();
    notifyListeners();
  }

  void selectSpecificDate(DateTime date) {
    _focusedDate = date;
    calendarController.displayDate = date;
    notifyListeners();
  }

  void toggleChatSidebar() {
    _isChatSidebarOpen = !_isChatSidebarOpen;
    notifyListeners();
  }

  // Thêm sự kiện mới
  Future<void> addNewEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String category,
    String description = '',
  }) async {
    final created = await _apiService.createEvent(
      title: title,
      startTime: startTime,
      endTime: endTime,
      category: category,
      description: description,
    );
    _allEvents.add(created);
    notifyListeners();
  }

  // Sửa sự kiện
  Future<void> editEvent({
    required int id,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String category,
    String description = '',
  }) async {
    final updated = await _apiService.updateEvent(
      id: id,
      title: title,
      startTime: startTime,
      endTime: endTime,
      category: category,
      description: description,
    );
    final idx = _allEvents.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _allEvents[idx] = updated;
      notifyListeners();
    }
  }

  // Xóa sự kiện
  Future<void> removeEvent(int id) async {
    await _apiService.deleteEvent(id);
    _allEvents.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // Gửi tin nhắn trong khung Chat (Sẵn sàng nối API AI sau mốc 13/11)
  void sendUserChatMessage(String text) {
    if (text.trim().isEmpty) return;
    chatMessages.add({'isUser': true, 'text': text});
    notifyListeners();

    // Phản hồi mẫu giao diện (Sau 13/11 chỉ cần thay bằng lệnh gọi API /api/chat)
    Future.delayed(const Duration(milliseconds: 500), () {
      chatMessages.add({
        'isUser': false,
        'text': 'Đã ghi nhận yêu cầu: "$text". (Tính năng tự động bóc tách NLP sẽ kích hoạt ở Giai đoạn 4).',
      });
      notifyListeners();
    });
  }
}