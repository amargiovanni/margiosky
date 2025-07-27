class PostRecord {
  final String text;
  final DateTime createdAt;
  
  PostRecord({
    required this.text,
    required this.createdAt,
  });
  
  factory PostRecord.fromJson(Map<String, dynamic> json) {
    return PostRecord(
      text: json['text'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}