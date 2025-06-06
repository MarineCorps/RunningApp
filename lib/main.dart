import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 추가
import 'package:runrun/screen/login_screen.dart';
import 'package:runrun/screen/main_screen.dart';
import 'package:runrun/screen/profile_input_screen.dart';
import 'package:kakao_flutter_sdk_common/kakao_flutter_sdk_common.dart';
import 'package:runrun/services/kakao_login_api.dart';
import 'controllers/user_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Firebase 초기화
  KakaoSdk.init(
    nativeAppKey: 'b214809fe8faa50ab8921678979694c9',
    javaScriptAppKey: '8c2efe4fad4c494d7551200e5fcb1b26',
  );

  // 앱 시작 시 로그인 상태 복원
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedLoginType = prefs.getString('login_type');

  runApp(MyApp(savedLoginType: savedLoginType));
}

class MyApp extends StatelessWidget {
  final String? savedLoginType;

  const MyApp({Key? key, this.savedLoginType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserController(kakaoLoginApi: KakaoLoginApi(), savedLoginType: savedLoginType),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: kDebugMode,
        title: 'Running App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Roboto',
        ),
        // 로그인 상태에 따라 초기 화면 결정
        home: Consumer<UserController>(
          builder: (context, userController, child) {
            if (userController.isLoggedIn) {
              return MainScreen(); // 로그인된 경우 메인 화면으로
            } else {
              return const LoginScreen(); // 로그인되지 않은 경우 로그인 화면
            }
          },
        ),
        routes: {
          '/profile_input': (context) => ProfileInputScreen(
              userId: ModalRoute.of(context)!.settings.arguments as String),
          '/main_screen': (context) => MainScreen(),
        },
      ),
    );
  }
}
