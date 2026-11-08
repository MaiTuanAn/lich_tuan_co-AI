import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late DateTime _start;
  late DateTime _end;
  late String _category;
  String? _errorMsg;
  bool _submitting = false;

  bool get isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existingEvent;
    final cats = context.read<CalendarProvider>().categories;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _start = e?.startTime ?? widget.initialStartTime ?? DateTime.now();
    _end = e?.endTime ?? _start.add(const Duration(hours: 1));
    _category = e?.category ?? cats.first.name;
  }

  Future<void> _pickDateTime(bool isStart) async {
    final init = isStart ? _start : _end;
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(init),
    );
    if (t == null) return;

    setState(() {
      final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      if (isStart) {
        _start = dt;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(hours: 1));
      } else {
        _end = dt;
      }
      _errorMsg = null;
    });
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Vui lòng nhập tiêu đề sự kiện!');
      return;
    }
    setState(() {
      _submitting = true;
      _errorMsg = null;
    });

    final provider = context.read<CalendarProvider>();
    try {
      if (isEditing) {
        await provider.editEvent(
          id: widget.existingEvent!.id,
          title: _titleCtrl.text.trim(),
          startTime: _start,
          endTime: _end,
          category: _category,
          description: _descCtrl.text.trim(),
        );
      } else {
        await provider.addNewEvent(
          title: _titleCtrl.text.trim(),
          startTime: _start,
          endTime: _end,
          category: _category,
          description: _descCtrl.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMsg = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CalendarProvider>().categories;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEditing ? 'Chỉnh sửa Sự kiện' : 'Tạo Sự kiện Mới',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_errorMsg != null)
                Container(
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
                          _errorMsg!,
                          style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tên sự kiện *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: categories.any((c) => c.name == _category)
                    ? _category
                    : categories.first.name,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                    .toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 12),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
                title: Text('Bắt đầu: ${DateFormat('dd/MM/yyyy HH:mm').format(_start)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _pickDateTime(true),
              ),
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
                title: Text('Kết thúc: ${DateFormat('dd/MM/yyyy HH:mm').format(_end)}'),
                trailing: const Icon(Icons.access_time),
                onTap: () => _pickDateTime(false),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú / Link họp',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _save,
          child: Text(isEditing ? 'Lưu thay đổi' : 'Tạo sự kiện'),
        ),
      ],
    );
  }
}
