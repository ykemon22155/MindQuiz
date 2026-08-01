import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:quiz_application_app/services/bdapps_auth_service.dart';

/// Firestore-backed replacement for the original Hive-based local question store.
///
/// The public API (`initialize`, `myQuestions`, `addQuestion`, `updateQuestion`,
/// `deleteQuestion`) is intentionally kept identical so existing callers
/// (`add_question.dart`, `added_question.dart`) keep working without changes.
class HiveDatabase {
  // Single Firestore collection that stores every locally authored question.
  // Each document id matches the question's `id` field for easy lookup.
  static final CollectionReference<Map<String, dynamic>> _questions =
  FirebaseFirestore.instance.collection('local_questions');

  static bool _initialized = false;

  /// Idempotent initializer. Safe to call multiple times.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    // Touch the collection once so offline cache is warmed up.
    try {
      await _questions.limit(1).get();
    } catch (e) {
      debugPrint('HiveDatabase.initialize warning: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// Returns every question authored on this device / by this user.
  /// Falls back to a synchronous in-memory cache loaded on demand.
  static List<Map<String, dynamic>> get myQuestions => _cache;

  static final List<Map<String, dynamic>> _cache = [];

  /// Async variant used by callers that want to await fresh data.
  static Future<List<Map<String, dynamic>>?> fetchQuestions() async {
    // NOTE: field is still named 'ownerUid' in Firestore for backward
    // compatibility with any documents already written under the old
    // Firebase-uid scheme. It now holds a phone number instead. Renaming
    // the field would require migrating existing docs — do that
    // separately if you want the naming to match going forward.
    final ownerKey = BdAppsAuthService().currentPhone;
    try {
      Query<Map<String, dynamic>> query = _questions;
      if (ownerKey != null) {
        query = query.where('ownerUid', isEqualTo: ownerKey);
      }
      final snapshot = await query.orderBy('createdAt', descending: true).get();
      final results = snapshot.docs
          .map((doc) => Map<String, dynamic>.from(doc.data())..['id'] = doc.id)
          .toList();
      _cache
        ..clear()
        ..addAll(results);
      return results;
    } catch (e) {
      debugPrint('HiveDatabase.fetchQuestions error: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Append a new question. Accepts the same Map shape that the Hive version did.
  static Future<void> addQuestion(Map<String, dynamic> question) async {
    final id = question['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final payload = Map<String, dynamic>.from(question)..['id'] = id;

    try {
      final ownerKey = BdAppsAuthService().currentPhone;
      if (ownerKey != null) payload['ownerUid'] = ownerKey;
      payload['createdAt'] = FieldValue.serverTimestamp();
      payload['updatedAt'] = FieldValue.serverTimestamp();
      await _questions.doc(id).set(payload, SetOptions(merge: true));
      _cache.add(payload);
    } catch (e) {
      debugPrint('HiveDatabase.addQuestion error: $e');
      rethrow;
    }
  }

  /// Replace an existing question identified by its `id` field.
  static Future<void> updateQuestion(Map<String, dynamic> question) async {
    final id = question['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('Question must include an "id" field to be updated.');
    }
    final payload = Map<String, dynamic>.from(question)
      ..['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _questions.doc(id).set(payload, SetOptions(merge: true));
      final index =
      _cache.indexWhere((q) => q['id']?.toString() == id);
      if (index != -1) _cache[index] = payload;
    } catch (e) {
      debugPrint('HiveDatabase.updateQuestion error: $e');
      rethrow;
    }
  }

  /// Delete a question identified by its `id` field.
  static Future<void> deleteQuestion(Map<String, dynamic> question) async {
    final id = question['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ArgumentError('Question must include an "id" field to be deleted.');
    }
    try {
      await _questions.doc(id).delete();
      _cache.removeWhere((q) => q['id']?.toString() == id);
    } catch (e) {
      debugPrint('HiveDatabase.deleteQuestion error: $e');
      rethrow;
    }
  }
}