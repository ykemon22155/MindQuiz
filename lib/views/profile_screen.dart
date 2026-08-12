import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quiz_application_app/services/bdapps_api.dart';
import 'package:quiz_application_app/services/bdapps_auth_service.dart';
import 'package:quiz_application_app/services/user_data.dart';
import 'package:quiz_application_app/views/auth_gate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final BdAppsAuthService _authService = BdAppsAuthService();
  final BdAppsApi _api = BdAppsApi();
  final ImagePicker _picker = ImagePicker();

  String userPhone = "";
  bool isLoading = true;
  bool _isUnsubscribing = false;
  bool _isSavingName = false;
  bool _isUploadingAvatar = false;
  bool _isEditingName = false;

  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final session = await _authService.getStoredAuthSession();
      if (mounted) {
        setState(() {
          if (session != null && session.user.phone.isNotEmpty) {
            userPhone = session.user.phone;
          }
          _nameController.text = UserData.userName;
          isLoading = false;
        });
        UserData.load();
        _loadStoredProfileFields();
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Requirement 6/7: read back whatever name/avatar is already saved for
  /// this user (written by `_saveName` / `_pickAndUploadAvatar` below, or
  /// by an older session) so it shows immediately without waiting for an
  /// edit.
  Future<void> _loadStoredProfileFields() async {
    if (userPhone.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('leaderboard').doc(userPhone).get();
      final data = doc.data();
      if (data == null) return;
      final storedName = data['name'] as String?;
      final storedAvatar = data['avatarUrl'] as String?;
      if (storedName != null && storedName.isNotEmpty) {
        UserData.updateName(storedName);
        if (mounted) _nameController.text = storedName;
      }
      if (storedAvatar != null && storedAvatar.isNotEmpty) {
        UserData.updateAvatar(storedAvatar);
      }
    } catch (e) {
      debugPrint('Could not load stored profile fields: $e');
    }
  }

  // ---------------------------------------------------------------------
  // Requirement 5: editable Name — purely local/display, no backend
  // dependency (there's no generic "user profile" endpoint in
  // bdapps_api.dart — phone numbers there are subscriber identifiers,
  // not editable account fields). Safe to save directly.
  //
  // Mobile Number itself is intentionally NOT editable here — it's the
  // account identity tied to BDApps subscription + OTP login, and you've
  // asked to leave that flow (subscribe_page.dart / subscription_gate.dart
  // / enter_otp_page.dart) untouched. It's shown read-only below.
  // ---------------------------------------------------------------------
  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty.')),
      );
      return;
    }

    setState(() => _isSavingName = true);
    try {
      await FirebaseFirestore.instance.collection('leaderboard').doc(userPhone).set({
        'name': newName,
      }, SetOptions(merge: true));

      UserData.updateName(newName);

      if (!mounted) return;
      setState(() => _isEditingName = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update name: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingName = false);
    }
  }

  // ---------------------------------------------------------------------
  // Requirement 6/7: avatar upload / change / delete, synced globally.
  //
  // WEB NOTE: this reads raw bytes (`readAsBytes` + `putData`) instead of
  // `dart:io`'s `File`/`putFile`, because `image_picker` returns a `blob:`
  // URL on web (not a real filesystem path) that `File` can't open. Bytes
  // work identically on mobile and web, so there's no platform branching
  // needed and no local-file preview step — just a spinner until the
  // real upload URL comes back.
  // ---------------------------------------------------------------------
  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final bytes = await picked.readAsBytes();
      final ref = FirebaseStorage.instance.ref().child('profile_pictures/$userPhone.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      // Store the URL wherever other screens/users can read it from — the
      // same leaderboard doc that already carries this user's score, so
      // the Leaderboard screen can show it too (Requirement 7).
      await FirebaseFirestore.instance.collection('leaderboard').doc(userPhone).set({
        'avatarUrl': url,
      }, SetOptions(merge: true));

      UserData.updateAvatar(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _deleteAvatar() async {
    setState(() => _isUploadingAvatar = true);
    try {
      try {
        await FirebaseStorage.instance.ref().child('profile_pictures/$userPhone.jpg').delete();
      } catch (_) {
        // Fine if there was nothing to delete (e.g. already removed).
      }
      await FirebaseFirestore.instance.collection('leaderboard').doc(userPhone).set({
        'avatarUrl': FieldValue.delete(),
      }, SetOptions(merge: true));

      // Falls back to the default avatar automatically — UserData's
      // placeholder URL — and UserAvatar shows the default person icon.
      UserData.updateAvatar(null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            if (UserData.userImageUrl != UserData.placeholderImageUrl)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Remove photo', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Requirement 3: unsubscribe keeps history/score, only flips a flag.
  // This is the only Firestore-side addition kept from that requirement;
  // the subscribe/unsubscribe backend flow itself (bdapps_api.dart,
  // subscription_gate.dart, subscribe_page.dart) is untouched.
  // ---------------------------------------------------------------------
  Future<void> _handleUnsubscribe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsubscribe?'),
        content: const Text(
          'আপনি কি নিশ্চিত যে আনসাবস্ক্রাইব করতে চান? এর পরে আবার লগইন করতে হবে।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Unsubscribe',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isUnsubscribing = true);

    try {
      if (userPhone.isNotEmpty) {
        // ১. আগে ব্যাকএন্ডে আনসাবস্ক্রাইব রিকোয়েস্ট পাঠাবে
        await _api.unsubscribe(userPhone);

        // ২. Requirement 3: do NOT delete the leaderboard doc / score /
        // history. Just flag the account as unsubscribed so a future
        // resubscribe can keep adding to the same cumulative total.
        await FirebaseFirestore.instance.collection('leaderboard').doc(userPhone).set({
          'is_subscribed': false,
        }, SetOptions(merge: true));
      }

      // ৩. ব্যাকএন্ড সফল হলে লোকাল সেশন ক্লিয়ার করা
      await _authService.clearStoredAuthSession();
      UserData.reset();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have been unsubscribed.')),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
              (route) => false,
        );
      }
    } catch (e) {
      // ব্যাকএন্ড ফেল করলে এরর দেখাবে, লোকাল সেশন মুছবে না
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unsubscribe failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUnsubscribing = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    await _authService.clearStoredAuthSession();
    UserData.reset();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF4A2E2B);
    const primaryColor = Color(0xFFE27D60);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Requirement 6: avatar with an edit badge that opens
              // upload/change/delete options.
              GestureDetector(
                onTap: _isUploadingAvatar ? null : _showAvatarOptions,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 3),
                      ),
                      child: ListenableBuilder(
                        listenable: UserData.notifier,
                        builder: (context, _) {
                          final url = UserData.userImageUrl;
                          final isDefault = url == UserData.placeholderImageUrl;
                          // Web-safe: only ever a placeholder URL or a real
                          // https download URL, never a local file path.
                          return CircleAvatar(
                            radius: 60,
                            backgroundColor: primaryColor,
                            backgroundImage: isDefault ? null : NetworkImage(url),
                            child: isDefault
                                ? const Icon(Icons.person, size: 60, color: Colors.white)
                                : null,
                          );
                        },
                      ),
                    ),
                    if (_isUploadingAvatar)
                      const Positioned.fill(
                        child: Center(child: CircularProgressIndicator(color: Colors.white)),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Requirement 5: editable Name.
              if (_isEditingName) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _nameController.text = UserData.userName;
                          setState(() => _isEditingName = false);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                        onPressed: _isSavingName ? null : _saveName,
                        child: _isSavingName
                            ? const SizedBox(
                                height: 18, width: 18,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                ListenableBuilder(
                  listenable: UserData.notifier,
                  builder: (context, _) => GestureDetector(
                    onTap: () => setState(() => _isEditingName = true),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          UserData.userName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.edit, size: 16, color: primaryColor),
                      ],
                    ),
                  ),
                ),
              ],

              // Mobile Number — read-only, matching your original
              // behaviour. It's the BDApps/OTP account identity, so it's
              // intentionally not editable from here.
              if (userPhone.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  userPhone,
                  style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.7)),
                ),
              ],
              const SizedBox(height: 32),

              // Sign Out Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(
                  "Sign Out",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _handleSignOut,
              ),
              const SizedBox(height: 16),

              // Unsubscribe Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor, width: 1.5),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: _isUnsubscribing
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: primaryColor,
                  ),
                )
                    : const Icon(Icons.unsubscribe_rounded),
                label: const Text(
                  "Unsubscribe",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _isUnsubscribing ? null : _handleUnsubscribe,
              ),
            ],
          ),
        ),
      ),
    );
  }
}