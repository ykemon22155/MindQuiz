import 'package:flutter/material.dart';
import '../model/category_model.dart';
import '../views/quiz_screen.dart';

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category});

  final QuizCategory category;

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    // ক্যাটাগরির নাম খালি বা নাল হ্যান্ডেল করার জন্য সেফটি চেক
    final String firstLetter = category.name.isNotEmpty ? category.name[0] : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias, // রিম্পল ইফেক্ট এবং কন্টেন্ট বাইরে যাওয়া রোধ করতে
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizScreen(
                  categoryId: category.id,
                  categoryName: category.name,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: .25),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(
              minHeight: 110, // ফিক্সড হাইটের বদলে মিনিমাম হাইট ব্যবহার করা হলো যাতে ওভারফ্লো না হয়
            ),
            child: Stack(
              children: [
                // ব্যাকগ্রাউন্ড ওয়াটারমার্ক লেটার
                Positioned(
                  bottom: -40,
                  right: -10,
                  child: Text(
                    firstLetter,
                    style: TextStyle(
                      fontSize: 100, // সাইজ একটু কমিয়ে সেফ করা হলো
                      fontWeight: FontWeight.w100,
                      color: colorScheme.onSecondaryContainer.withValues(alpha: .1),
                    ),
                  ),
                ),
                // ক্যাটাগরির নাম
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    maxLines: 2, // টেক্সট বড় হলে সর্বোচ্চ ২ লাইন হতে পারবে
                    overflow: TextOverflow.ellipsis, // অতিরিক্ত বড় হলে ডট ডট দেখাবে
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}