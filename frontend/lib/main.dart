import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';
import 'models/event_model.dart';
import 'services/api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý Lịch Tuần',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const WeeklyCalendarScreen(),
    );
  }
}

class WeeklyCalendarScreen extends StatefulWidget {
  const WeeklyCalendarScreen({super.key});

  @override
  State<WeeklyCalendarScreen> createState() => _WeeklyCalendarScreenState();
}

class _WeeklyCalendarScreenState extends State<WeeklyCalendarScreen> {
  final ApiService _apiService = ApiService();
  List<EventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  // Tải danh sách lịch từ FastAPI
  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await _apiService.getEvents();
      setState(() => _events = events);
    } catch (e) {
      _showSnackbar('Lỗi kết nối Server: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  // Hộp thoại thêm sự kiện mới
  void _openAddEventDialog([DateTime? defaultStart]) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime start = defaultStart ?? DateTime.now();
    DateTime end = start.add(const Duration(hours: 1));
    String category = 'Công việc';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Thêm Lịch Mới', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Tên sự kiện / cuộc họp *'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: category,
                      decoration: const InputDecoration(labelText: 'Danh mục'),
                      items: ['Công việc', 'Học tập', 'Cá nhân', 'Khẩn cấp']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (val) => setDialogState(() => category = val!),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Bắt đầu: ${DateFormat('dd/MM/yyyy HH:mm').format(start)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await _pickDateTime(start);
                        if (picked != null) setDialogState(() => start = picked);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Kết thúc: ${DateFormat('dd/MM/yyyy HH:mm').format(end)}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final picked = await _pickDateTime(end);
                        if (picked != null) setDialogState(() => end = picked);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      _showSnackbar('Vui lòng nhập tên sự kiện', isError: true);
                      return;
                    }
                    try {
                      await _apiService.createEvent(
                        title: titleController.text.trim(),
                        startTime: start,
                        endTime: end,
                        category: category,
                        description: descController.text.trim(),
                      );
                      Navigator.pop(ctx);
                      _showSnackbar('Tạo sự kiện thành công!');
                      _fetchEvents();
                    } catch (e) {
                      _showSnackbar(e.toString().replaceAll('Exception: ', ''), isError: true);
                    }
                  },
                  child: const Text('Lưu sự kiện'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Chọn ngày và giờ
  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
    );
    if (date == null) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch Tuần Của Tôi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: _fetchEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SfCalendar(
              view: CalendarView.week,
              firstDayOfWeek: 1, // Thứ 2 là ngày đầu tuần
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 7,
                endHour: 22,
                timeIntervalHeight: 60,
                timeFormat: 'HH:mm',
              ),
              dataSource: _CalendarDataSource(_events),
              // Bấm vào khung giờ trống -> Mở tạo lịch nhanh
              onTap: (CalendarTapDetails details) {
                if (details.targetElement == CalendarElement.calendarCell && details.date != null) {
                  _openAddEventDialog(details.date);
                } else if (details.targetElement == CalendarElement.appointment && details.appointments != null) {
                  final EventModel event = details.appointments!.first;
                  _showEventDetail(event);
                }
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEventDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm lịch'),
      ),
    );
  }

  // Xem chi tiết & Xóa sự kiện
  void _showEventDetail(EventModel event) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(event.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Danh mục: ${event.category}'),
            Text('Thời gian: ${DateFormat('HH:mm dd/MM/yyyy').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Xóa sự kiện', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _apiService.deleteEvent(event.id);
                    _showSnackbar('Đã xóa sự kiện thành công');
                    _fetchEvents();
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// Cầu nối dữ liệu cho SfCalendar
class _CalendarDataSource extends CalendarDataSource {
  _CalendarDataSource(List<EventModel> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) => (appointments![index] as EventModel).startTime;

  @override
  DateTime getEndTime(int index) => (appointments![index] as EventModel).endTime;

  @override
  String getSubject(int index) => (appointments![index] as EventModel).title;

  @override
  Color getColor(int index) => (appointments![index] as EventModel).color;
}