import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quiz_application_app/l10n/app_localizations.dart';
import 'package:quiz_application_app/widgets/question_preview.dart';
import '../model/quiz_ques_model.dart';

class QuestionsFromApi extends StatefulWidget {
  const QuestionsFromApi({super.key});

  @override
  State<QuestionsFromApi> createState() => _QuestionsFromApiState();
}

class _QuestionsFromApiState extends State<QuestionsFromApi> {
  List<QuizQuestion> allQuestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // কনটেক্সট সেফভাবে ব্যবহারের জন্য পোস্ট ফ্রেম কলব্যাক ব্যবহার করা হয়েছে
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadAllQuestions();
    });
  }

  Future<void> loadAllQuestions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      String url = "https://sadiks-quiz-apihub.lovable.app/api/v1/categories/1/questions";
      var response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        var result = jsonDecode(response.body);
        List data = result["data"];
        setState(() {
          allQuestions = data.map((item) => QuizQuestion.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToLoadQuestions)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(l10n.locallyAddedQuestions),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : allQuestions.isEmpty
          ? Center(
        child: Text(
          l10n.noCategoriesFound, // বা আপনার প্রয়োজনীয় মেসেজ
          style: TextStyle(color: colorScheme.outline, fontSize: 16),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadAllQuestions,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: allQuestions.length,
          itemBuilder: (context, index) => QuestionPreview(
            question: allQuestions[index],
            index: index,
          ),
        ),
      ),
    );
  }
}