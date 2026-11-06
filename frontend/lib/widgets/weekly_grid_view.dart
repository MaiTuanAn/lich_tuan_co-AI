import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../models/event_model.dart';
import '../providers/calendar_provider.dart';
import 'event_form_dialog.dart';

class WeeklyGridView extends StatelessWidget {
  const WeeklyGridView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Colors.white,
      child: SfCalendar(
        controller: provider.calendarController,
        view: provider.currentView,
        firstDayOfWeek: 1, // Thứ Hai là ngày đầu tuần
        headerHeight: 0,   // Đã dùng TopHeaderBar tùy biến ở trên
        todayHighlightColor: Colors.redAccent,
        showCurrentTimeIndicator: true, // Đường kẻ đỏ chỉ thời gian thực
        timeSlotViewSettings: const TimeSlotViewSettings(
          startHour: 7,
          endHour: 22,
          timeIntervalHeight: 64,
          timeFormat: 'HH:mm',
          dayFormat: 'EEE',
          dateFormat: 'd',
        ),
        dataSource: _EventDataSource(provider.filteredEvents),

        // Tùy biến giao diện từng khối sự kiện (Pastel Card + Viền màu đậm bên trái)
        appointmentBuilder: (context, calendarAppointmentDetails) {
          final EventModel event = calendarAppointmentDetails.appointments.first;
          final timeStr =
              '${DateFormat('HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: event.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: event.primaryColor, width: 4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: event.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: event.primaryColor.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          );
        },

        // Xử lý khi người dùng bấm vào ô trống hoặc bấm vào sự kiện
        onTap: (CalendarTapDetails details) {
          if (details.targetElement == CalendarElement.calendarCell &&
              details.date != null) {
            // Bấm vào ô giờ trống -> Mở form Tạo mới tại đúng giờ đó
            showDialog(
              context: context,
              builder: (_) => EventFormDialog(initialStartTime: details.date),
            );
          } else if (details.targetElement == CalendarElement.appointment &&
              details.appointments != null &&
              details.appointments!.isNotEmpty) {
            // Bấm vào sự kiện đã có -> Mở form Sửa / Xóa
            final EventModel selectedEvent = details.appointments!.first;
            showDialog(
              context: context,
              builder: (_) => EventFormDialog(existingEvent: selectedEvent),
            );
          }
        },
      ),
    );
  }
}

class _EventDataSource extends CalendarDataSource {
  _EventDataSource(List<EventModel> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) => (appointments![index] as EventModel).startTime;

  @override
  DateTime getEndTime(int index) => (appointments![index] as EventModel).endTime;

  @override
  String getSubject(int index) => (appointments![index] as EventModel).title;

  @override
  Color getColor(int index) => (appointments![index] as EventModel).backgroundColor;
}
