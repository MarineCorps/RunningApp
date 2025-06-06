import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInApi {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        return {
          'displayName': account.displayName,
          'photoUrl': account.photoUrl,
        };
      }
    } catch (error) {
      print('Google 로그인 실패: $error');
    }
    return null;
  }
}
