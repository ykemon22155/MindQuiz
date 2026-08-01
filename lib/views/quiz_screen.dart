import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../model/quiz_ques_model.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const QuizScreen({super.key, required this.categoryId, required this.categoryName});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<QuizQuestion>> _questionsFuture;

  int _currentQuestionIndex = 0;
  int _score = 0;
  int _selectedIndex = -1;
  Timer? _timer;
  int _timeLeft = 15;
  bool _isTimerStarted = false;
  bool _isSubmitting = false; // ডাবল সাবমিট রোধ করার জন্য

  @override
  void initState() {
    super.initState();
    _questionsFuture = _apiService.fetchQuestions(widget.categoryId);
  }

  void _startTimer(List<QuizQuestion> questions) {
    _timer?.cancel();
    _timeLeft = 15;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft == 0) {
        _nextQuestion(questions);
      } else {
        setState(() {
          _timeLeft--;
        });
      }
    });
  }

  // ফায়ারস্টোরে স্কোর সেভ করার মেথড
  Future<void> _saveScoreToFirestore(int finalScore) async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      String userName = user?.displayName ?? user?.email ?? 'Quiz Player';

      // যদি ইউজার ইমেল বা নাম না থাকে, তবে একটি ডিফল্ট নাম দিতে পারেন
      if (userName.contains('@')) {
        userName = userName.split('@')[0]; // ইমেলের আগের অংশ নাম হিসেবে নেওয়া
      }

      // ফায়ারস্টোরের 'leaderboard' কালেকশনে স্কোর সেভ করা
      await FirebaseFirestore.instance.collection('leaderboard').add({
        'name': userName,
        'score': finalScore,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Failed to save score: $e");
    }
  }

  void _nextQuestion(List<QuizQuestion> questions) async {
    _timer?.cancel();
    final currentQuestion = questions[_currentQuestionIndex];

    // উত্তর ঠিক হলে স্কোর বাড়ানো
    if (_selectedIndex != -1) {
      if (_selectedIndex == currentQuestion.correctAnswerIndex) {
        setState(() {
          _score++;
        });
      }
    }

    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedIndex = -1;
      });
      _startTimer(questions);
    } else {
      // কুইজ শেষ! ফায়ারস্টোরে স্কোর সেভ করে তারপর রেজাল্ট স্ক্রিনে যাওয়া
      await _saveScoreToFirestore(_score);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              score: _score,
              totalQuestions: questions.length,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFF8F0);
    const primaryColor = Color(0xFFE27D60);
    const secondaryColor = Color(0xFF2A9D8F);
    const textColor = Color(0xFF4A2E2B);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: FutureBuilder<List<QuizQuestion>>(
          future: _questionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(primaryColor)));
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No questions found.'));
            }

            final questions = snapshot.data!;

            if (!_isTimerStarted) {
              _isTimerStarted = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _startTimer(questions);
              });
            }

            final currentQuestion = questions[_currentQuestionIndex];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(widget.categoryName, style: const TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                      TextButton(
                        onPressed: _isSubmitting ? null : () => _nextQuestion(questions),
                        child: Text("Skip", style: TextStyle(color: textColor.withValues(alpha: 0.6), fontWeight: FontWeight.w600)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // টাইমার ডিসপ্লে
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_currentQuestionIndex + 1}/${questions.length}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: secondaryColor),
                      ),
                      Text(
                        "Time left: ${_timeLeft}s",
                        style: TextStyle(fontWeight: FontWeight.bold, color: _timeLeft <= 5 ? Colors.red : secondaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // প্রশ্ন
                  Text(
                    currentQuestion.question,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor, height: 1.35),
                  ),
                  const SizedBox(height: 28),

                  // অপশন লিস্ট
                  Expanded(
                    child: ListView.builder(
                      itemCount: currentQuestion.options.length,
                      itemBuilder: (context, index) {
                        bool isSelected = _selectedIndex == index;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? secondaryColor : primaryColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                              child: Text(
                                currentQuestion.options[index],
                                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // নেক্সট বাটন
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: textColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _isSubmitting ? null : () => _nextQuestion(questions),
                      child: _isSubmitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : Text(_currentQuestionIndex == questions.length - 1 ? "Finish Quiz" : "Next Question"),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}