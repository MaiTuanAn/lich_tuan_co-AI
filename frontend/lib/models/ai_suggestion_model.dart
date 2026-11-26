class AiSuggestion {
  final String title;
  final String category; // tên danh mục
  final DateTime start; // giờ địa phương
  final DateTime end;

  AiSuggestion({
    required this.title,
    required this.category,
    required this.start,
    required this.end,
  });

  factory AiSuggestion.fromJson(Map<String, dynamic> json) {
    return AiSuggestion(
      title: json['title'] as String,
      category: (json['category'] as String?) ?? '',
      // Chuỗi dạng "2026-11-26T09:00" không có múi giờ -> Dart hiểu là giờ địa phương
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }
}
