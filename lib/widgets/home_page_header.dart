import 'package:flutter/material.dart';
import 'package:quiz_application_app/views/profile_screen.dart';

import '../l10n/app_localizations.dart';

class HomePageHeader extends StatelessWidget {
  const HomePageHeader({super.key});

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Row(
      spacing: 16,
      children: [
        // Profile picture
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          ),
          child: Container(
            height: 72,
            width: 72,
            decoration: BoxDecoration(
              border: Border.all(color: colorScheme.primary, width: 2),
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        // Name, Greeting
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${l10n.hi}, Guest",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                l10n.readyToPlay,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Points (placeholder local-only value)
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            spacing: 10,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.secondary,
                foregroundColor: colorScheme.onSecondary,
                child: const Icon(Icons.diamond_outlined, size: 20),
              ),
              Text(
                "0",
                style: TextStyle(
                  color: colorScheme.onSecondaryContainer,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}