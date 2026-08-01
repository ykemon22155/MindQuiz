import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'leaderboard.dart'; // লিডারবোর্ড স্ক্রিনের সঠিক পাথ এখানে দিয়ে দেবেন

class ResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;

  const ResultScreen({super.key, required this.score, required this.totalQuestions});

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF4A2E2B);
    const primaryColor = Color(0xFFE27D60);
    const secondaryColor = Color(0xFF41B3A3);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events_rounded, size: 100, color: Colors.amber),
              const SizedBox(height: 24),
              const Text("Congratulations!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 8),
              const Text("You did a great job!", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 48),
                decoration: BoxDecoration(color: const Color(0xFFFFF1E6), borderRadius: BorderRadius.circular(24)),
                child: Column(
                  children: [
                    const Text("YOUR SCORE", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("$score / $totalQuestions", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // লিডারবোর্ড দেখার বাটন
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Leaderboard()),
                  );
                },
                child: const Text("View Leaderboard", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              // ব্যাক টু হোম বাটন
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondaryColor,
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: secondaryColor, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                  );
                },
                child: const Text("Back to Home", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}