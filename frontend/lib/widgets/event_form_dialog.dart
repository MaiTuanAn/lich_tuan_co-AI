import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../models/event_model.dart';
import '../providers/calendar_provider.dart';

class EventFormDialog extends StatefulWidget {
  final DateTime? initialStartTime;
  final EventModel? existingEvent;

  const EventFormDialog({
    super.key,
    this.initialStartTime,
    this.existingEvent,
  });

  @override
  State<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<EventFormDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late DateTime _startTime;
  late DateTime _endTime;
  late String _category;
  String? _errorMessage;
  bool _isSubmitting = false;

  bool get isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descController = TextEditingController(text: existing?.description ?? '');
    _startTime = existing?.startTime ?? widget.initialStartTime ?? DateTime.now();
    _endTime = existing?.endTime ?? _startTime.add(const Duration(hours: 1));
    _category = existing?.category ?? 'Công việc';
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    setState(() {
      final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      if (isStart) {
        _startTime = selected;
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = selected;
      }
      _errorMessage = null;
    });
  }

  Future<void> _submitForm() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập tên sự kiện!');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final provider = context.read<CalendarProvider>();
    try {
      if (isEditing) {
        await provider.editEvent(
          id: widget.existingEvent!.id,
          title: _titleController.text.trim(),
          startTime: _startTime,
          endTime: _endTime,
          category: _category,
          description: _descController.text.trim(),
        );
      } else {
        await provider.addNewEvent(
          title: _titleController.text.trim(),
          startTime: _startTime,
          endTime: _endTime,
          category: _category,
          description: _descController.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Hiển thị lỗi trùng lịch trả về từ Backend FastAPI ngay trên Dialog
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        isEditing ? 'Chỉnh sửa Sự kiện' : 'Tạo Sự kiện Mới',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hộp cảnh báo đỏ nếu bị Trùng lịch (Conflict Detected)
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề sự kiện *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  border: OutlineInputBorder(),
                ),
                items: AppColors.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 14),

              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.borderColor),
                ),
                title: Text('Bắt đầu: ${DateFormat('dd/MM/yyyy HH:mm').format(_startTime)}'),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickDateTime(true),
              ),
              const SizedBox(height: 10),

              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.borderColor),
                ),
                title: Text('Kết thúc: ${DateFormat('dd/MM/yyyy HH:mm').format(_endTime)}'),
                trailing: const Icon(Icons.schedule),
                onTap: () => _pickDateTime(false),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú chi tiết',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Nút Xóa nếu đang xem sự kiện cũ
        if (isEditing)
          TextButton.icon(
            onPressed: () async {
              await context.read<CalendarProvider>().removeEvent(widget.existingEvent!.id);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade600,
            foregroundColor: Colors.white,
          ),
          child: Text(isEditing ? 'Cập nhật' : 'Lưu lịch'),
        ),
      ],
    );
  }
}