import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/category_model.dart';
import '../models/event_model.dart';
import '../services/auth_service.dart';
import '../services/category_repository.dart';
import '../services/event_repository.dart';

class CalendarProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final EventRepository _eventRepo = EventRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final CalendarController calendarController = CalendarController();

  // 1. Trạng thái Đăng nhập & Giao diện
  // "Đã đăng nhập" = có tài khoản thật. Khách ẩn danh vẫn có phiên nhưng isLoggedIn = false.
  bool _isLoggedIn = false;
  String _userName = 'Khách';
  String _userEmail = '';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isChatSidebarOpen = false;
  bool _isLoading = false;
  DateTime _focusedDate = DateTime.now();

  // 2. Cấu hình Cài đặt (Settings State) - chưa lưu lên cloud, sẽ làm ở bước sau
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

  // 3. Danh mục & sự kiện: tải từ Supabase (không còn hard-code)
  final List<CategoryModel> _categories = [];
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
    final hidden = _categories.where((c) => !c.isVisible).map((c) => c.name).toSet();
    return _allEvents.where((e) => !hidden.contains(e.category)).toList();
  }

  int countEventsByCategory(String categoryName) {
    return _allEvents.where((e) => e.category == categoryName).length;
  }

  Color getColorForCategory(String categoryName) {
    for (final c in _categories) {
      if (c.name == categoryName) return c.color;
    }
    return _categories.isNotEmpty ? _categories.first.color : const Color(0xFF2563EB);
  }

  String? _categoryIdByName(String name) {
    for (final c in _categories) {
      if (c.name == name) return c.id;
    }
    return _categories.isNotEmpty ? _categories.first.id : null;
  }

  // ---------------------------------------------------------------------------
  // KHỞI TẠO: gọi 1 lần khi mở app (MainLayoutScreen.initState)
  // Khôi phục phiên đăng nhập; chưa có thì tạo khách ẩn danh; rồi tải dữ liệu.
  // ---------------------------------------------------------------------------
  Future<void> bootstrap() async {
    await _runWithLoading(() async {
      await _auth.ensureSession();
      await _reloadAll();
    });
  }

  /// Tải lại danh mục + sự kiện (nút làm mới trong hồ sơ cũng gọi hàm này)
  Future<void> loadEvents() async {
    await _runWithLoading(_reloadAll);
  }

  Future<void> _reloadAll() async {
    await _syncUserState();
    final cats = await _categoryRepo.fetchAll();
    _categories
      ..clear()
      ..addAll(cats);
    _allEvents = await _eventRepo.fetchAll();
  }

  Future<void> _syncUserState() async {
    final user = _auth.currentUser;
    _isLoggedIn = user != null && !user.isAnonymous;
    _userEmail = _isLoggedIn ? (user?.email ?? '') : '';
    _userName = _isLoggedIn ? (await _auth.fetchFullName() ?? _userEmail) : 'Khách';
    _isChatSidebarOpen = _isLoggedIn;
  }

  Future<void> _runWithLoading(Future<void> Function() job) async {
    _isLoading = true;
    notifyListeners();
    try {
      await job();
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- XÁC THỰC (UI bắt lỗi và hiển thị message tiếng Việt) ---
  Future<void> registerAccount({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _auth.signUp(fullName: fullName, email: email, password: password);
    await loadEvents();
  }

  Future<void> loginAccount({
    required String email,
    required String password,
  }) async {
    await _auth.signIn(email: email, password: password);
    await loadEvents();
  }

  Future<void> changeUserPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _auth.changePassword(oldPassword: oldPassword, newPassword: newPassword);
  }

  Future<void> logoutToGuestMode() async {
    chatMessages.removeRange(1, chatMessages.length); // giữ lại lời chào đầu
    await _auth.signOutToGuest();
    await loadEvents();
  }

  // --- GIAO DIỆN (THEME & SIDEBAR) ---
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleChatSidebar() {
    if (!_isLoggedIn) return;
    _isChatSidebarOpen = !_isChatSidebarOpen;
    notifyListeners();
  }

  // --- DANH MỤC (lưu lên cloud) ---
  void toggleCategoryVisibility(String name) {
    final idx = _categories.indexWhere((c) => c.name == name);
    if (idx == -1) return;
    final cat = _categories[idx];
    cat.isVisible = !cat.isVisible;
    notifyListeners();
    _categoryRepo
        .setVisible(cat.id, cat.isVisible)
        .catchError((e) => debugPrint('Lỗi lưu danh mục: $e'));
  }

  void selectAllCategories() {
    for (final c in _categories) {
      c.isVisible = true;
    }
    notifyListeners();
    _categoryRepo.showAll().catchError((e) => debugPrint('Lỗi lưu danh mục: $e'));
  }

  Future<void> addCategory(String name, Color color) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    if (_categories.any((c) => c.name.toLowerCase() == clean.toLowerCase())) return;
    try {
      final created = await _categoryRepo.add(clean, color);
      _categories.add(created);
      notifyListeners();
    } catch (e) {
      debugPrint('Lỗi tạo danh mục: $e');
    }
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

  // --- CRUD SỰ KIỆN (lỗi được ném lên cho UI hiển thị) ---
  Future<void> addNewEvent({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String category,
    String description = '',
  }) async {
    final created = await _eventRepo.create(
      title: title,
      startTime: startTime,
      endTime: endTime,
      categoryId: _categoryIdByName(category),
      description: description,
    );
    _allEvents.add(created);
    notifyListeners();
  }

  Future<void> editEvent({
    required String id,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    required String category,
    String description = '',
  }) async {
    final updated = await _eventRepo.update(
      id: id,
      title: title,
      startTime: startTime,
      endTime: endTime,
      categoryId: _categoryIdByName(category),
      description: description,
    );
    final idx = _allEvents.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _allEvents[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> removeEvent(String id) async {
    await _eventRepo.delete(id);
    _allEvents.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // --- CHAT AI (vẫn là mock, sẽ nối Edge Function ở bước sau) ---
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
