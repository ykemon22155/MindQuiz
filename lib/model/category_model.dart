class QuizCategory {
  final String id;
  final String name;
  final String description;

  QuizCategory({required this.id, required this.name, this.description = ''});

  factory QuizCategory.fromJson(Map<String, dynamic> json) {
    return QuizCategory(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}