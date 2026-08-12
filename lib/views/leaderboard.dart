import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_application_app/l10n/app_localizations.dart';

class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(l10n?.leaderboard ?? 'Leaderboard'),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        // Single-field orderBy only — this needs NO manual composite index.
        // The previous version added `.orderBy('username')` as a second
        // sort field, which Firestore can only run against a composite
        // index. Without that index existing, it throws
        // failed-precondition, which then hits the known Flutter-Web
        // interop bug and shows up as the generic TypeError instead of
        // the real "requires an index" message.
        future: FirebaseFirestore.instance
            .collection('leaderboard')
            .orderBy('score', descending: true) // সর্বোচ্চ (সঞ্চিত) স্কোর যার, সে উপরে থাকবে
            .limit(20) // টপ ২০ জন ইউজারের লিস্ট
            .get(),
        builder: (context, snapshot) {
          // ১. লোডিং অবস্থা
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ২. কোনো এরর হলে
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading leaderboard data: ${snapshot.error}',
                  style: TextStyle(color: colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // ৩. ডেটা না থাকলে
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      size: 96,
                      color: colorScheme.primary.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.leaderboardComingSoon ?? 'No leaderboard data yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n?.noDataAvailable ?? 'Play and set your score!',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // ৪. ডেটা থাকলে লিস্ট আকারে শো করবে
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            padding: const EdgeInsets.all(16.0),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              // 'name' is what quiz_screen.dart actually writes; 'username'
              // is kept as a fallback only in case older docs used it.
              final name = data['name'] ?? data['username'] ?? 'Anonymous';
              // Requirement 3: this is now the cumulative total across
              // every quiz the user has ever finished (quiz_screen.dart
              // writes `FieldValue.increment(...)` instead of overwriting).
              final score = data['score'] ?? 0;
              // Unsubscribed users keep their score/history — we just show
              // a small muted badge instead of hiding them.
              final isSubscribed = data['is_subscribed'] ?? true;
              // Requirement 7: synced avatar. quiz_screen.dart / profile_screen.dart
              // write this field whenever the signed-in user has uploaded a
              // photo, so any player's picture shows up here too.
              final avatarUrl = data['avatarUrl'] as String?;
              final rank = index + 1;

              // টপ ৩ জনের জন্য আলাদা মেডেল বা কালার কোড
              Color? rankColor;
              if (rank == 1) {
                rankColor = Colors.amber;
              } else if (rank == 2) {
                rankColor = Colors.grey.shade400;
              } else if (rank == 3) {
                rankColor = Colors.brown.shade300;
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundColor: rankColor ?? colorScheme.primary.withValues(alpha: 0.2),
                        backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Text(
                                '$rank',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: rankColor != null ? Colors.black : colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                      if (avatarUrl != null && avatarUrl.isNotEmpty)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: CircleAvatar(
                            radius: 9,
                            backgroundColor: rankColor ?? colorScheme.primary,
                            child: Text(
                              '$rank',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: isSubscribed == false
                      ? Text(
                          'Inactive subscription',
                          style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                        )
                      : null,
                  trailing: Text(
                    '$score pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

