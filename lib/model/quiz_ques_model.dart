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
    final options = (json['options'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        [];

    // ------------------------------------------------------------------
    // Requirement 2 (score bug) — ROOT CAUSE FOUND:
    //
    // The live API (checked directly against
    // https://sadiks-quiz-apihub.lovable.app/api/v1/categories/1/questions)
    // returns the correct-answer field as:
    //
    //     "answerIndex": 1
    //
    // but this model was reading `json['correctAnswerIndex']`, a key
    // that DOES NOT EXIST anywhere in the real response. Because that
    // key was always missing, `int.tryParse(null.toString())` always
    // failed and silently fell back to `0` for every single question —
    // meaning the app scored EVERY question as if option index 0 were
    // always correct, no matter what the real answer was. This is why
    // scores came out wrong: it had nothing to do with how the score was
    // compared/counted in quiz_screen.dart, it was that the "correct
    // answer" the app was comparing against was fabricated.
    //
    // Fix: read `answerIndex` first (the real field), then fall back to
    // a couple of other plausible names in case the backend changes or
    // a different endpoint version is used, so this keeps working either
    // way. Also clamp to a valid range so a bad value can never point
    // outside `options`.
    // ------------------------------------------------------------------
    final rawCorrect = json['answerIndex'] ??
        json['correctAnswerIndex'] ??
        json['correct_answer_index'] ??
        json['correct_answer'] ??
        json['correctAnswer'];

    int correctIndex = 0;
    if (rawCorrect != null) {
      final parsedAsInt = int.tryParse(rawCorrect.toString());
      if (parsedAsInt != null && parsedAsInt >= 0 && (options.isEmpty || parsedAsInt < options.length)) {
        correctIndex = parsedAsInt;
      } else {
        // Fallback for the (currently unseen, but possible) case where
        // the backend sends the answer as text instead of an index.
        final rawText = rawCorrect.toString().trim().toLowerCase();
        final foundIndex = options.indexWhere((o) => o.trim().toLowerCase() == rawText);
        if (foundIndex >= 0) correctIndex = foundIndex;
      }
    }

    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options: options,
      correctAnswerIndex: correctIndex,
      categoryId: json['categoryId']?.toString(),
      mark: int.tryParse(json['mark']?.toString() ?? '10') ?? 10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'answerIndex': correctAnswerIndex,
      'categoryId': categoryId,
      'mark': mark,
    };
  }
}