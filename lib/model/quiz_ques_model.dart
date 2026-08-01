class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctAnswerIndex;
  final String? categoryId;
  final int mark;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswerIndex,
    this.categoryId,
    this.mark = 10,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      // এখানে অপশনে ইন্টিজার বা যাই থাকুক না কেন, তা স্বয়ংক্রিয়ভাবে স্ট্রিংয়ে রূপান্তরিত হয়ে যাবে
      options: (json['options'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      // correctAnswerIndex যদি ভুলবশত স্ট্রিং আকারে আসে, তবে তা ইন্টিজারে কনভার্ট হবে
      correctAnswerIndex:
          int.tryParse(json['correctAnswerIndex']?.toString() ?? '0') ?? 0,
      categoryId: json['categoryId']?.toString(),
      mark: int.tryParse(json['mark']?.toString() ?? '10') ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'categoryId': categoryId,
      'mark': mark,
    };
  }
}