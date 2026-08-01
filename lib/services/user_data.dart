import 'package:quiz_application_app/services/auth_service.dart';

class UserData {
  static String placeholderImageUrl = 'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png';

  static String? get _photoURL => AuthService().currentUser?.photoURL;
  static String? get _displayName => AuthService().currentUser?.displayName;
  static String? get _email => AuthService().currentUser?.email;

  static String userImageUrl = _photoURL ?? placeholderImageUrl;
  static String userName = _displayName ?? '--';
  static String userEmail = _email ?? '--';
  static String userMobileNumber = '--';
  static bool isSubscribed = false;
  static String userJoined =
      AuthService().currentUser?.metadata.creationTime?.toString().split(" ").first ?? '--';
}
