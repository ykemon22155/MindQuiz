import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_application_app/services/bdapps_auth_service.dart';
import 'package:quiz_application_app/services/user_data.dart';
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
  final BdAppsAuthService _authService = BdAppsAuthService();
  late Future<List<QuizQuestion>> _questionsFuture;

  int _currentQuestionIndex = 0;
  int _score = 0;
  int _selectedIndex = -1;
  Timer? _timer;
  int _timeLeft = 15;
  bool _isTimerStarted = false;
  bool _isSubmitting = false; // ডাবল সাবমিট রোধ করার জন্য (final save)

  // Requirement 2 (score bug — secondary hardening; the primary cause was
  // in quiz_ques_model.dart reading the wrong JSON key, now fixed there).
  // This guard additionally protects against the timer firing and a
  // button tap both calling `_nextQuestion` for the SAME question in the
  // same frame, which would have counted that answer twice.
  bool _isAdvancing = false;

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

  // ফোন নাম্বার আড়াল করে দেখানোর জন্য (যেমন: 017****789)
  String _maskPhone(String phone) {
    if (phone.length < 7) return phone;
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 3)}';
  }

  // Requirement 3: Firestore leaderboard write.
  //
  // OLD BEHAVIOUR: read the existing doc, and only overwrote `score` if
  // the just-finished quiz's score was strictly greater than the stored
  // one — so the leaderboard only ever showed the single BEST attempt,
  // never the sum of everything the user has played.
  //
  // NEW BEHAVIOUR: every finished quiz ADDS its score to the user's
  // running total via `FieldValue.increment(...)`, which also works if
  // the document doesn't exist yet (Firestore treats a missing numeric
  // field as 0 before incrementing). We stamp `is_subscribed: true` here
  // because playing a quiz only happens while subscribed; unsubscribing
  // (profile_screen.dart) flips this flag to false WITHOUT touching
  // `score`, so history/score is never lost and resubscribing simply
  // resumes adding to the same total.
  Future<void> _saveScoreToFirestore(int finalScore) async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });

    try {
      final session = await _authService.getStoredAuthSession();
      final phone = session?.user.phone;

      if (phone == null || phone.isEmpty) {
        debugPrint("No logged-in phone number found; skipping leaderboard save.");
        return;
      }

      final docRef = FirebaseFirestore.instance.collection('leaderboard').doc(phone);

      // Prefer a real display name if the user has set one on the Profile
      // page; otherwise fall back to the masked phone number as before.
      final profileName = UserData.userName;
      final displayName = (profileName.isNotEmpty && profileName != 'Quiz Player')
          ? profileName
          : _maskPhone(phone);

      final avatarUrl = UserData.userImageUrl;
      final hasRealAvatar = avatarUrl != UserData.placeholderImageUrl && avatarUrl.startsWith('http');

      await docRef.set({
        'name': displayName,
        'phone': phone,
        'score': FieldValue.increment(finalScore), // cumulative total, never overwritten
        'is_subscribed': true,
        'lastPlayedAt': FieldValue.serverTimestamp(),
        if (hasRealAvatar) 'avatarUrl': avatarUrl,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Failed to save score: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _nextQuestion(List<QuizQuestion> questions) async {
    if (_isAdvancing) return; // guard against double-fire (timer + tap)
    _isAdvancing = true;

    _timer?.cancel();
    final currentQuestion = questions[_currentQuestionIndex];

    // `_selectedIndex == -1` means "no answer chosen" (timed out or
    // skipped) and must NOT be counted as correct. `correctAnswerIndex`
    // now comes from the real API field (see quiz_ques_model.dart).
    if (_selectedIndex != -1 &&
        currentQuestion.correctAnswerIndex >= 0 &&
        currentQuestion.correctAnswerIndex < currentQuestion.options.length &&
        _selectedIndex == currentQuestion.correctAnswerIndex) {
      _score++;
    }

    if (_currentQuestionIndex < questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedIndex = -1;
      });
      _isAdvancing = false;
      _startTimer(questions);
    } else {
      // কুইজ শেষ! ফায়ারস্টোরে স্কোর সেভ করে তারপর রেজাল্ট স্ক্রিনে যাওয়া
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
      // Intentionally not resetting _isAdvancing here — this screen is
      // about to be popped, so no further taps can reach this state.
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