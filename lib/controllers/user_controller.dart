import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:runrun/services/kakao_login_api.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore 연동
import 'package:shared_preferences/shared_preferences.dart'; // 로그인 상태 저장

class UserController with ChangeNotifier {
  User? _user; // 카카오 사용자 정보
  KakaoLoginApi kakaoLoginApi;
  GoogleSignInAccount? _googleUser; // 구글 사용자 정보

  User? get user => _user;
  GoogleSignInAccount? get googleUser => _googleUser;

  UserController({required this.kakaoLoginApi, String? savedLoginType}) {
    if (savedLoginType != null) {
      _restoreLoginState(savedLoginType); // 앱 시작 시 로그인 상태 복원
    }
  }

  /// 사용자 고유 ID 반환
  String get userId {
    if (_user != null) {
      return _user!.id.toString(); // 카카오 사용자 ID
    } else if (_googleUser != null) {
      return _googleUser!.email; // 구글 이메일을 ID로 사용
    } else {
      return "guest_user_${DateTime.now().millisecondsSinceEpoch}"; // 게스트 사용자
    }
  }

  /// Firestore에 사용자 정보 저장
  Future<void> saveUserInfoToFirestore() async {
    final userId = this.userId; // 현재 사용자 ID
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    try {
      await userDoc.set({
        'id': userId,
        'name': _user?.properties?['nickname'] ?? _googleUser?.displayName ?? 'Guest',
        'email': _googleUser?.email ?? _user?.kakaoAccount?.email ?? '',
        'profile_image': _user?.properties?['profile_image'] ?? _googleUser?.photoUrl ?? '',
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print('사용자 정보가 Firestore에 저장되었습니다.');
    } catch (e) {
      print('사용자 정보 저장 중 오류 발생: $e');
    }
  }

  /// 로그인 상태 저장
  Future<void> _saveLoginType(String loginType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('login_type', loginType);
    print('로그인 상태가 저장되었습니다: $loginType');
  }

  /// 로그인 상태 복원
  Future<void> _restoreLoginState(String loginType) async {
    if (loginType == 'kakao') {
      // 카카오 로그인 상태 복원
      try {
        User user = await UserApi.instance.me();
        _user = user;
        notifyListeners();
        print('카카오 로그인 상태가 복원되었습니다.');
      } catch (e) {
        print('카카오 로그인 복원 실패: $e');
      }
    } else if (loginType == 'google') {
      // 구글 로그인 상태 복원
      try {
        final googleSignIn = GoogleSignIn();
        final account = await googleSignIn.signInSilently();
        if (account != null) {
          _googleUser = account;
          notifyListeners();
          print('구글 로그인 상태가 복원되었습니다.');
        }
      } catch (e) {
        print('구글 로그인 복원 실패: $e');
      }
    }
  }

  /// 로그인 상태 확인
  bool get isLoggedIn {
    return _user != null || _googleUser != null;
  }

  /// 카카오 로그인
  Future<bool> kakaoLogin() async {
    try {
      final user = await kakaoLoginApi.signWithKakao();
      if (user != null && user.id != null) {
        _user = user; // 카카오 사용자 정보 저장
        notifyListeners();
        await saveUserInfoToFirestore(); // 사용자 정보 Firestore에 저장
        await _saveLoginType('kakao'); // 로그인 상태 저장
        return true;
      }
      return false;
    } catch (error) {
      print('카카오 로그인 중 오류 발생: $error');
      return false;
    }
  }

  /// 구글 로그인
  Future<bool> googleLogin() async {
    try {
      final googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account != null && account.email.isNotEmpty) {
        _googleUser = account; // 구글 사용자 정보 저장
        notifyListeners();
        await saveUserInfoToFirestore(); // 사용자 정보 Firestore에 저장
        await _saveLoginType('google'); // 로그인 상태 저장
        return true;
      }
      return false;
    } catch (error) {
      print("구글 로그인 중 오류 발생: $error");
      return false;
    }
  }

  /// 카카오 로그아웃
  Future<void> kakaoLogout() async {
    if (_user != null) {
      try {
        await UserApi.instance.logout();
        _user = null;
        notifyListeners();
        print('카카오 로그아웃 성공');
      } catch (error) {
        print("카카오 로그아웃 실패: $error");
      }
    }
  }

  /// 구글 로그아웃
  Future<void> googleLogout() async {
    if (_googleUser != null) {
      try {
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        _googleUser = null;
        notifyListeners();
        print('구글 로그아웃 성공');
      } catch (error) {
        print("구글 로그아웃 실패: $error");
      }
    }
  }

  /// 전체 로그아웃
  Future<void> logout() async {
    await kakaoLogout();
    await googleLogout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('login_type'); // 로그인 상태 삭제
    print('전체 로그아웃 완료 및 상태 초기화');
  }
}
