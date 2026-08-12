import 'package:flutter/material.dart';
import 'package:quiz_application_app/l10n/app_localizations.dart';
import 'package:quiz_application_app/widgets/category_list_section.dart';

/// Requirement 4: this is the dedicated "Categories" tab (see
/// `main_shell.dart`). It previously duplicated the Home tab's greeting
/// header, avatar, and "Practice More" banner on top of the category
/// list — none of which belongs on a page whose only job is to list
/// categories. It now renders strictly the category list.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFFFF8F0);
    const textColor = Color(0xFF4A2E2B);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Text(
          l10n?.categories ?? 'Categories',
          style: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: const CategoryListSection(showHeading: false),
        ),
      ),
    );
  }
}