import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../core/app_colors.dart';
import '../models/event_model.dart';
import '../providers/calendar_provider.dart';
import 'event_form_dialog.dart';

class WeeklyGridView extends StatelessWidget {
  const WeeklyGridView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final isDark = provider.isDarkMode;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFCBD5E1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SfCalendar(
          controller: provider.calendarController,
          view: CalendarView.week,
          firstDayOfWeek: 1, // Thứ 2 đầu tuần
          headerHeight: 0,
          cellBorderColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          todayHighlightColor: Colors.redAccent,
          showCurrentTimeIndicator: true,
          viewHeaderStyle: ViewHeaderStyle(
            backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            dayTextStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
            dateTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          timeSlotViewSettings: TimeSlotViewSettings(
            startHour: 7,
            endHour: 21,
            timeIntervalHeight: 62,
            timeFormat: provider.use24HourFormat ? 'HH:mm' : 'hh a',
            timeTextStyle: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          dataSource: _EventDataSource(provider.filteredEvents),

          // Tùy biến thẻ sự kiện có hiệu ứng Hover + Tooltip + Nút Sửa/Xóa nhanh
          appointmentBuilder: (context, details) {
            final EventModel event = details.appointments.first;
            final baseColor = provider.getColorForCategory(event.category);
            return _HoverableEventCard(
              event: event,
              baseColor: baseColor,
              isDark: isDark,
            );
          },

          // Bấm vào ô giờ trống để tạo lịch
          onTap: (CalendarTapDetails details) {
            if (details.targetElement == CalendarElement.calendarCell &&
                details.date != null) {
              showDialog(
                context: context,
                builder: (_) => EventFormDialog(initialStartTime: details.date),
              );
            }
          },
        ),
      ),
    );
  }
}

// Widget thẻ sự kiện hỗ trợ rê chuột (Hover) hiện nút Sửa/Xóa và Tooltip chi tiết
class _HoverableEventCard extends StatefulWidget {
  final EventModel event;
  final Color baseColor;
  final bool isDark;

  const _HoverableEventCard({
    required this.event,
    required this.baseColor,
    required this.isDark,
  });

  @override
  State<_HoverableEventCard> createState() => _HoverableEventCardState();
}

class _HoverableEventCardState extends State<_HoverableEventCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = AppColors.getEventBackground(widget.baseColor, widget.isDark);
    final textColor = AppColors.getEventTextColor(widget.baseColor, widget.isDark);
    final timeRange =
        '${DateFormat('HH:mm').format(widget.event.startTime)} – ${DateFormat('HH:mm').format(widget.event.endTime)}';

    return Tooltip(
      richMessage: WidgetSpan(
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.event.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.baseColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.event.category,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                timeRange,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
              if (widget.event.description.isNotEmpty) ...[
                const Divider(color: Colors.white24, height: 14),
                Text(
                  widget.event.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
          ),
        ],
      ),
      waitDuration: const Duration(milliseconds: 200),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => EventFormDialog(existingEvent: widget.event),
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered ? widget.baseColor : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: widget.baseColor.withValues(alpha: 0.45),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeRange,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),

                // Hai nút Sửa (✏️) và Xóa (🗑️) xuất hiện ở góc phải khi rê chuột vào
                if (_isHovered)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => EventFormDialog(existingEvent: widget.event),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(Icons.edit, size: 14, color: Colors.white),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              context.read<CalendarProvider>().removeEvent(widget.event.id);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(3),
                              child: Icon(Icons.delete_outline, size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
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
}
