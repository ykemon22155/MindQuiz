import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/category_model.dart';
import '../model/quiz_ques_model.dart';

class ApiService {
  static const String baseUrl = 'https://sadiks-quiz-apihub.lovable.app/api/v1';

  // ক্যাটাগরি ফেচ করার জন্য
  static Future<List<QuizCategory>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> categoriesList = responseData['data'];

        return categoriesList.map((item) => QuizCategory.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // Alias kept for backward compatibility
  Future<List<QuizCategory>> fetchCategories() => getCategories();

  static Future<void> createCategory(String name, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'description': description}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to create category: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  static Future<void> updateCategory(String id, String name, String description) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/categories/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'description': description}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to update category: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  static Future<void> deleteCategory(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/categories/$id'));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to delete category: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // প্রশ্ন ফেচ করার জন্য
  static Future<List<QuizQuestion>> getQuestions(String categoryId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories/$categoryId/questions'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> questionsList = responseData['data'];

        return questionsList.map((item) => QuizQuestion.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load questions');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // Alias kept for backward compatibility
  Future<List<QuizQuestion>> fetchQuestions(String categoryId) => getQuestions(categoryId);

  static Future<void> deleteQuestion(String questionId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/questions/$questionId'));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to delete question: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

// নতুন প্রশ্ন তৈরি করার জন্য
  static Future<void> createQuestion(int categoryId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/categories/$categoryId/questions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to create question: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // প্রশ্ন আপডেট করার জন্য
  static Future<void> updateQuestion(String questionId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/questions/$questionId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to update question: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }

  // চ্যাট বা এআই রেসপন্স পাওয়ার জন্য (আপনার প্রোভাইডারে ব্যবহৃত ফাংশন)
  static Future<String?> getResponseFromAI(String message) async {
    try {
      // এখানে আপনার এআই এপিআই বা ওপেনরাউটার (OpenRouter) এর এন্ডপয়েন্ট বসাতে পারেন
      // উদাহরণস্বরূপ একটি ডামি পোস্ট রিকোয়েস্ট:
      /*
      final response = await http.post(
        Uri.parse('YOUR_AI_API_URL'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': message}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'];
      }
      */

      // টেস্টের জন্য আপাতত সিমুলেটেড রেসপন্স:
      await Future.delayed(const Duration(seconds: 1));
      return "I received your message: '$message'. How can I assist you further with your quiz?";
    } catch (e) {
      return null;
    }
  }
}