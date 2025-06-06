import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoLoginApi {
  // 카카오톡으로 로그인
  Future<User?> signWithKakao() async {
    final UserApi api = UserApi.instance;

    if (await isKakaoTalkInstalled()) {
      try {
        await api.loginWithKakaoTalk();
        return await api.me();
      } catch (error) {
        print('카카오톡으로 로그인 실패 $error');
        if (error is PlatformException && error.code == 'CANCELED') {
          return null; // 로그인 취소
        }
      }
    }

    // 카카오톡이 설치되지 않은 경우 카카오 계정으로 로그인
    try {
      await api.loginWithKakaoAccount();
      return await api.me();
    } catch (error) {
      print('카카오계정으로 로그인 실패 $error');
      return null;
    }
  }
}
