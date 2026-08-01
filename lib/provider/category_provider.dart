import 'package:flutter/foundation.dart';
import '../model/category_model.dart';
import '../services/api_service.dart';

class CategoryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<QuizCategory> _categories = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<QuizCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _categories = await _apiService.fetchCategories();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}