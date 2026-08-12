import 'package:flutter/material.dart';
import 'package:quiz_application_app/widgets/category_list_section.dart';
import 'package:quiz_application_app/widgets/user_avatar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFF8F0);
    const textColor = Color(0xFF4A2E2B);
    const secondaryColor = Color(0xFF2A9D8F);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
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
                  // Requirement 7: was a static CircleAvatar with a fixed
                  // person icon. Now shows the user's uploaded photo and
                  // stays in sync the instant it changes on the Profile page.
                  const UserAvatar(),
                ],
              ),
              const SizedBox(height: 24),

              // --------------------------------------------------------
              // Requirement 1: the orange "Exp. Points / Ranking" banner
              // that used to sit here has been REMOVED entirely.
              // --------------------------------------------------------

              // Practice More - Daily Quiz banner
              Text(
                "⚡ Practice More",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Daily Quiz", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(
                            "20 mixed questions",
                            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Requirement 4: this used to embed the whole CategoryScreen
              // (greeting + banner + list all over again). It now embeds
              // just the list itself.
              const CategoryListSection(),
            ],
          ),
        ),
      ),
    );
  }
}