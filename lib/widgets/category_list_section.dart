import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../model/category_model.dart';
import '../views/quiz_screen.dart';

/// Requirement 4 fix — explanation:
///
/// `main_shell.dart` uses `CategoryScreen` in TWO places:
///   1. Embedded inside `HomeScreen` (the Home tab), and
///   2. As its own standalone "Categories" tab.
///
/// Before this change, `CategoryScreen` was one big widget containing the
/// greeting header, the avatar, the "Practice More / Daily Quiz" banner,
/// AND the category list all together. That meant the dedicated
/// "Categories" tab was showing the same greeting/banner "unrelated
/// content" a second time, instead of strictly showing just categories.
///
/// This widget is now the ONLY thing that talks to the categories API and
/// renders the list. `CategoryScreen` (the tab) wraps just this. `HomeScreen`
/// also embeds just this, underneath its own greeting/banner, so nothing
/// is duplicated and the Categories tab is finally "strictly categories".
class CategoryListSection extends StatefulWidget {
  const CategoryListSection({super.key, this.showHeading = true});

  /// Set to false if the caller already renders its own section heading.
  final bool showHeading;

  @override
  State<CategoryListSection> createState() => _CategoryListSectionState();
}

class _CategoryListSectionState extends State<CategoryListSection> {
  final ApiService _apiService = ApiService();
  late Future<List<QuizCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _apiService.fetchCategories();
  }

  /// Requirement 4: defensively drop anything that doesn't look like a
  /// real, displayable category (blank id/name, or a duplicate id) before
  /// it ever reaches the list — in case the API ever mixes in a
  /// placeholder/test/duplicate row.
  List<QuizCategory> _sanitize(List<QuizCategory> raw) {
    final seenIds = <String>{};
    return raw.where((c) {
      final hasValidId = c.id.trim().isNotEmpty;
      final hasValidName = c.name.trim().isNotEmpty;
      if (!hasValidId || !hasValidName) return false;
      if (seenIds.contains(c.id)) return false;
      seenIds.add(c.id);
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE27D60);
    const textColor = Color(0xFF4A2E2B);
    const cardBackgroundColor = Color(0xFFFFF1E6);

    return FutureBuilder<List<QuizCategory>>(
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
        }

        final categories = _sanitize(snapshot.data ?? []);

        if (categories.isEmpty) {
          return const Center(child: Text('No categories available.'));
        }

        const alphabet = ["A", "B", "C", "D", "E", "F", "G"];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeading) ...[
              Text(
                "📚 Continue Studying",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final currentLetter = alphabet[index % alphabet.length];

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
            ),
          ],
        );
      },
    );
  }
}