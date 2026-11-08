import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/category_model.dart';
import '../models/event_model.dart';
import '../services/api_service.dart';

class CalendarProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final CalendarController calendarController = CalendarController();

  // 1. Trạng thái Đăng nhập & Giao diện
  bool _isLoggedIn = false; // Mặc định ở Chế độ Khách (Guest Mode)
  String _userName = 'Nguyễn Văn A';
  String _userEmail = 'nguyenvana@gmail.com';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isChatSidebarOpen = false;
  bool _isLoading = false;
  DateTime _focusedDate = DateTime.now();

  // 2. Cấu hình Cài đặt (Settings State)
  String appLanguage = 'Tiếng Việt';
  String dateFormat = 'DD/MM/YYYY';
  bool use24HourFormat = true;
  bool startOnBoot = false;
  String defaultViewName = 'Week';
  String startDayOfWeek = 'Monday';
  String timezone = 'Asia/Ho_Chi_Minh (GMT+7)';
  String defaultDuration = '60 mins';
  bool useCustomApiKey = false;
  bool conflictAutoResolution = true;
  bool smartSlotSuggestions = true;
  String aiResponseStyle = 'Concise / Brief';
  bool desktopPushNoti = true;
  bool soundAlerts = true;
  String defaultReminder = '15 minutes before event';
  bool dailyBriefing = true;
  bool conflictAlerts = true;

  // 3. Danh sách Danh mục mặc định
  final List<CategoryModel> _categories = [
    CategoryModel(name: 'Công việc', color: const Color(0xFF2563EB)),
    CategoryModel(name: 'Học tập', color: const Color(0xFF16A34A)),
    CategoryModel(name: 'Cá nhân', color: const Color(0xFFEA580C)),
    CategoryModel(name: 'Khẩn cấp', color: const Color(0xFFDC2626)),
  ];

  List<EventModel> _allEvents = [];

  final List<Map<String, dynamic>> chatMessages = [
    {
      'isUser': false,
      'text': 'Xin chào! Tôi là Trợ lý AI. Tôi có thể tìm khung giờ trống không trùng lịch và tự động lên lịch cho bạn.',
    },
  ];

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  String get userName => _userName;
  String get userEmail => _userEmail;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isChatSidebarOpen => _isLoggedIn && _isChatSidebarOpen;
  bool get isLoading => _isLoading;
  DateTime get focusedDate => _focusedDate;
  List<CategoryModel> get categories => _categories;

  // Lọc sự kiện theo các danh mục đang bật
  List<EventModel> get filteredEvents {
    final activeNames = _categories.where((c) => c.isVisible).map((c) => c.name).toSet();
    return _allEvents.where((e) => activeNames.contains(e.category)).toList();
  }

  // Đếm số sự kiện trong từng danh mục
  int countEventsByCategory(String categoryName) {
    return _allEvents.where((e) => e.category == categoryName).length;
  }

  // Lấy màu của danh mục
  Color getColorForCategory(String categoryName) {
    final found = _categories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => _categories.first,
    );
    return found.color;
  }

  // --- HÀNH ĐỘNG XÁC THỰC (AUTH / GUEST) ---
  void login(String name, String email) {
    _isLoggedIn = true;
    _userName = name.isNotEmpty ? name : 'Nguyễn Văn A';
    _userEmail = email.isNotEmpty ? email : 'nguyenvana@gmail.com';
    _isChatSidebarOpen = true; // Mở sẵn khung AI khi vừa đăng nhập
    notifyListeners();
  }

  void logoutToGuestMode() {
    _isLoggedIn = false;
    _isChatSidebarOpen = false; // Ẩn ngay khung AI khi về chế độ Khách
    notifyListeners();
  }

  // --- HÀNH ĐỘNG GIAO DIỆN (THEME & SIDEBAR) ---
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleChatSidebar() {
    if (!_isLoggedIn) return;
    _isChatSidebarOpen = !_isChatSidebarOpen;
    notifyListeners();
  }

  // --- QUẢN LÝ DANH MỤC (CATEGORIES) ---
  void toggleCategoryVisibility(String name) {
    final idx = _categories.indexWhere((c) => c.name == name);
    if (idx != -1) {
      _categories[idx].isVisible = !_categories[idx].isVisible;
      notifyListeners();
    }
  }

  void selectAllCategories() {
    for (var c in _categories) {
      c.isVisible = true;
    }
    notifyListeners();
  }

  void addCategory(String name, Color color) {
    if (name.trim().isEmpty) return;
    if (_categories.any((c) => c.name.toLowerCase() == name.trim().toLowerCase())) return;
    _categories.add(CategoryModel(name: name.trim(), color: color));
    notifyListeners();
  }

  // --- ĐIỀU HƯỚNG LỊCH TUẦN ---
  void goToToday() {
    _focusedDate = DateTime.now();
    calendarController.displayDate = _focusedDate;
    notifyListeners();
  }

  void goToPreviousWeek() {
    calendarController.backward!();
    _focusedDate = calendarController.displayDate ?? DateTime.now();
    notifyListeners();
  }

  void goToNextWeek() {
    calendarController.forward!();
    _focusedDate = calendarController.displayDate ?? DateTime.now();
    notifyListeners();
  }

  void jumpToDate(DateTime date) {
    _focusedDate = date;
    calendarController.displayDate = date;
    notifyListeners();
  }

  // --- GỌI API CRUD SỰ KIỆN ---
  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allEvents = await _apiService.fetchEvents();
      // Tự động bổ sung danh mục nếu sự kiện từ server có danh mục mới
      for (var ev in _allEvents) {
        if (!_categories.any((c) => c.name == ev.category)) {
          _categories.add(CategoryModel(name: ev.category, color: const Color(0xFF9333EA)));
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải lịch: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

  Future<void> removeEvent(int id) async {
    await _apiService.deleteEvent(id);
    _allEvents.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void sendUserChatMessage(String text) {
    if (text.trim().isEmpty) return;
    chatMessages.add({'isUser': true, 'text': text});
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      chatMessages.add({
        'isUser': false,
        'text': 'Tôi đã tìm thấy khung giờ trống phù hợp cho "$text". Bạn có muốn lên lịch ngay không?',
        'suggestedTitle': text,
      });
      notifyListeners();
    });
  }

  void notifySettingsUpdated() {
    notifyListeners();
  }
}
