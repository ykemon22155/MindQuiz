import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quiz_application_app/services/bdapps_auth_service.dart';
import 'package:quiz_application_app/services/user_data.dart';

/// NOTE: `phone` is the unique key for each user's document, sourced from
/// BdAppsAuthService's in-memory cache. This is captured once when
/// DatabaseService() is constructed — make sure
/// BdAppsAuthService().restoreSessionIfPossible() has already completed
/// (e.g. at app startup) before you construct this, or `phone` will be
/// null even for a logged-in user.
class DatabaseService {
  final FirebaseFirestore database = FirebaseFirestore.instance;
  final String? phone = BdAppsAuthService().currentPhone;

  String userDatabaseLabel = "users";
  String quizSessionDatabaseLabel = "sessions";

  //Get User's Total Score
  Stream<int> get totalScoreStream {
    if (phone == null) return Stream.value(0);
    return database.collection(userDatabaseLabel).doc(phone).snapshots().map((doc) {
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['totalScore'] ?? 0;
      } else {
        return 0;
      }
    });
  }

  //Get a one-time snapshot of the current user's Firestore document.
  //Returns null if the user is not signed in, the document does not exist, or read fails.
  Future<Map<String, dynamic>?> getUserDocument() async {
    if (phone == null) return null;
    try {
      final doc = await database.collection(userDatabaseLabel).doc(phone).get();
      if (!doc.exists) return null;
      final data = doc.data();
      final mobile = data?['mobileNumber'];
      if (mobile is String && mobile.trim().isNotEmpty) {
        UserData.userMobileNumber = mobile;
      }
      return data;
    } on Exception catch (e) {
      debugPrint("Failed to read user document: $e");
      return null;
    }
  }

  //Save / update the current user's profile fields.
  //With phone as the doc ID, mobileNumber is mostly redundant with the key
  //itself, but kept as a field too so it shows up directly in query results
  //and exports without needing the doc ID.
  Future<bool> saveMobileNumber(String mobileNumber) async {
    if (phone == null) return false;
    try {
      await database.collection(userDatabaseLabel).doc(phone).set({
        'mobileNumber': mobileNumber,
        'displayName': UserData.userName,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      UserData.userMobileNumber = mobileNumber;
      return true;
    } on Exception catch (e) {
      debugPrint("Failed to save mobile number: $e");
      return false;
    }
  }

  //Save Quiz Session
  Future<void> saveQuizSession({required int gainedScore, required int totalAttempt, required int totalCorrect, required String category}) async {
    if (phone == null) return;
    final userRef = database.collection(userDatabaseLabel).doc(phone);
    final sessionRef = userRef.collection(quizSessionDatabaseLabel).doc();
    await database.runTransaction((transaction) async {
      // 1. Get current total score
      DocumentSnapshot userDoc = await transaction.get(userRef);
      int existingCurrentScore = 0;
      int newCurrentScore = 0;
      if (userDoc.exists) {
        existingCurrentScore = (userDoc.data() as Map<String, dynamic>)['totalScore'] ?? 0;
      }
      newCurrentScore = existingCurrentScore + gainedScore;
      // 2. Update user's total score
      transaction.set(userRef, {
        'totalScore': newCurrentScore,
        'mobileNumber': phone,
        'displayName': UserData.userName,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      // 3. Append session data
      transaction.set(sessionRef, {
        'quizCategory': category,
        'dateTime': FieldValue.serverTimestamp(),
        'totalAttempt': totalAttempt,
        'totalCorrect': totalCorrect,
        'gainedScore': gainedScore,
      });
    });
  }

  //Get user's session history
  Stream<QuerySnapshot> get sessionHistoryStream {
    if (phone == null) return Stream.empty();
    return database.collection(userDatabaseLabel).doc(phone).collection(quizSessionDatabaseLabel).orderBy('dateTime', descending: true).snapshots();
  }

  //Get all users info for leaderboard (ordered by totalScore)
  Stream<QuerySnapshot> get allUsersStream {
    return database.collection(userDatabaseLabel).orderBy('totalScore', descending: true).snapshots();
  }
}