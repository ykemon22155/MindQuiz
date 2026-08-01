import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../model/category_model.dart';
import 'quiz_screen.dart';
import 'leaderboard.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<QuizCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _apiService.fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFF8F0);
    const primaryColor = Color(0xFFE27D60);
    const secondaryColor = Color(0xFF2A9D8F);
    const textColor = Color(0xFF4A2E2B);
    const cardBackgroundColor = Color(0xFFFFF1E6);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User header section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "👋 Hi there,",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Great to see you again!",
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withValues(alpha: 0.6),
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

              // 2. Exp. Points & Ranking box (GestureDetector -> leaderboard)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Leaderboard(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.white, size: 26),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("0", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text("Exp. Points", style: TextStyle(fontSize: 11, color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 32, color: Colors.white24),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 26),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("0", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text("Ranking", style: TextStyle(fontSize: 11, color: Colors.white70)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 3. Practice More - Daily Quiz banner
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

              // 4. Continue Studying - API category list
              Text(
                "📚 Continue Studying",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 12),

              FutureBuilder<List<QuizCategory>>(
                future: _categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(primaryColor),
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "❌ Error: ${snapshot.error}",
                        style: const TextStyle(color: textColor),
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No categories available.'));
                  }

                  final categories = snapshot.data!;
                  List<String> alphabet = ["A", "B", "C", "D", "E", "F", "G"];

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      String currentLetter = alphabet[index % alphabet.length];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ListTile(
                          tileColor: cardBackgroundColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  currentLetter,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                const Text(
                                  "Class",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    height: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Text(
                            categories[index].name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            "12 questions left",
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withValues(alpha: 0.5),
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textColor),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizScreen(
                                  categoryId: categories[index].id,
                                  categoryName: categories[index].name,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}