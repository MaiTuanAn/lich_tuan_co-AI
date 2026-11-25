class EventModel {
  final String id; // uuid từ Supabase
  final String title;
  final DateTime startTime; // giờ local
  final DateTime endTime; // giờ local
  final String category; // tên danh mục (lấy từ bảng categories)
  final String? categoryId;
  final String description;

  EventModel({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.category,
    this.categoryId,
    this.description = '',
  });

  /// Dữ liệu trả về từ: select('*, categories(name)')
  factory EventModel.fromJson(Map<String, dynamic> json) {
    final cat = json['categories'];
    final catName = cat is Map<String, dynamic> ? cat['name'] as String? : null;

    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      // DB lưu timestamptz (UTC) -> đổi sang giờ máy người dùng để hiển thị
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      category: catName ?? 'Khác',
      categoryId: json['category_id'] as String?,
      description: (json['description'] as String?) ?? '',
    );
  }
}
