import 'package:flutter/foundation.dart';
import '../model/quiz_ques_model.dart';
import '../services/api_service.dart';

class QuizProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _selectedIndex = -1;
  bool _isLoading = false;
  String _errorMessage = '';

  List<QuizQuestion> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get score => _score;
  int get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchQuestions(String categoryId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _questions = await _apiService.fetchQuestions(categoryId);
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedIndex = -1;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectOption(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  bool nextQuestion() {
    if (_selectedIndex != -1) {
      if (_selectedIndex == _questions[_currentQuestionIndex].correctAnswerIndex) {
        _score++;
      }
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      _selectedIndex = -1;
      notifyListeners();
      return true;
    } else {
      notifyListeners();
      return false;
    }
  }

  void resetQuiz() {
    _currentQuestionIndex = 0;
    _score = 0;
    _selectedIndex = -1;
    notifyListeners();
  }
}