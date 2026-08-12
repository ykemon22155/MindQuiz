import 'package:flutter/material.dart';
import 'package:quiz_application_app/services/user_data.dart';

/// Drop-in replacement for the old hard-coded:
/// ```dart
/// const CircleAvatar(
///   radius: 26,
///   backgroundColor: Color(0x33E27D60),
///   child: Icon(Icons.person_rounded, color: primaryColor, size: 28),
/// )
/// ```
/// Use `const UserAvatar()` anywhere the app previously showed that
/// static icon (Home header, Category header, Profile page). It reads
/// [UserData.userImageUrl] and rebuilds instantly whenever
/// [UserData.notifier] ticks — i.e. the instant the Profile page
/// uploads, changes, or removes a photo (Requirements 6 & 7).
///
/// WEB NOTE: this intentionally never touches `dart:io`/`File`.
/// [UserData.userImageUrl] is only ever the default placeholder URL or a
/// real `https://` Firebase Storage download URL — never a local file
/// path — so `NetworkImage` alone is enough and this works identically
/// on mobile and web. (An earlier version used `FileImage` for an
/// instant local preview on mobile; that path crashed on web because
/// `image_picker` returns a `blob:` URL there, not a real file — see
/// profile_screen.dart's `_pickAndUploadAvatar` for how the upload
/// itself avoids `File` too.)
class UserAvatar extends StatelessWidget {
  final double radius;
  final Color backgroundColor;
  final Color iconColor;

  const UserAvatar({
    super.key,
    this.radius = 26,
    this.backgroundColor = const Color(0x33E27D60),
    this.iconColor = const Color(0xFFE27D60),
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserData.notifier,
      builder: (context, _) {
        final url = UserData.userImageUrl;
        final isDefault = url == UserData.placeholderImageUrl;

        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor,
          backgroundImage: isDefault ? null : NetworkImage(url),
          child: isDefault
              ? Icon(Icons.person_rounded, color: iconColor, size: radius * 1.08)
              : null,
        );
      },
    );
  }
}