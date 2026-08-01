import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // kIsWeb চেক করার জন্য
import 'package:flutter/material.dart';
import 'package:quiz_application_app/l10n/app_localizations.dart';
import 'package:quiz_application_app/views/auth_gate.dart';

// আপনার প্রজেক্টে firebase_options.dart থাকলে এটি আনকমেন্ট (Uncomment) করুন:
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ১. আপনার যদি firebase_options.dart ফাইল থাকে তবে নিচের মতো অপশন পাস করুন:
  /*
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  */

  // ২. আর যদি ওয়েবের জন্য ফায়ারবেস কনফিগার করা না থাকে, তবে আপাতত এভাবে চালান:
  if (!kIsWeb) {
    await Firebase.initializeApp();
  }

  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindQuest Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFFCF9F2),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const AuthGate(),
    );
  }
}