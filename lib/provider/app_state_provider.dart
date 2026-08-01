import 'package:flutter/foundation.dart';

class AppStateProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // নতুন ভেরিয়েবলসমূহ (ফ্লোচার্ট অনুযায়ী)
  bool _isLoggedInWithGoogle = false;
  bool get isLoggedInWithGoogle => _isLoggedInWithGoogle;

  bool _hasMobileNumber = false;
  bool get hasMobileNumber => _hasMobileNumber;

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  // গুগল সাইন-ইন স্ট্যাটাস আপডেট করার ফাংশন
  void setGoogleLoginStatus(bool status) {
    _isLoggedInWithGoogle = status;
    notifyListeners();
  }

  // মোবাইল নাম্বার এবং সাবস্ক্রিপশন স্ট্যাটাস সেট করার ফাংশন
  void setUserSubscriptionStatus({required bool hasNumber, required bool isSubscribed}) {
    _hasMobileNumber = hasNumber;
    _isSubscribed = isSubscribed;
    notifyListeners();
  }

  // ইউজার আনসাবস্ক্রাইব করলে সবকিছু রিসেট করার ফাংশন
  void resetOnUnsubscribe() {
    _isLoggedInWithGoogle = false;
    _hasMobileNumber = false;
    _isSubscribed = false;
    notifyListeners();
  }
}