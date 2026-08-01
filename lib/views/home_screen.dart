import 'package:flutter/material.dart';
import 'package:quiz_application_app/views/category_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFF8F0);
    const textColor = Color(0xFF4A2E2B);
    const primaryColor = Color(0xFFE27D60);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ওয়েলকাম হেডার
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Back! 👋",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Ready for today's challenge?",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0x33E27D60),
                    child: Icon(Icons.person_rounded, color: primaryColor, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // হোম পেজের কন্টেন্ট বা ক্যাটাগরি স্ক্রিন
              const Expanded(
                child: CategoryScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}