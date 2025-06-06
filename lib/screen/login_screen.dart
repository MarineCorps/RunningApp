import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:runrun/controllers/user_controller.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _checkProfile(BuildContext context) async {
    final userId = context.read<UserController>().userId;

    if (userId.isNotEmpty) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      final snapshot = await userDoc.get();

      if (!snapshot.exists || snapshot.data()?['height'] == null || snapshot.data()?['weight'] == null) {
        // 유저 정보가 없거나 height, weight가 없을 경우 프로필 입력 화면으로 이동
        Navigator.pushReplacementNamed(context, '/profile_input', arguments: userId);
      } else {
        // 정보가 존재하면 메인 화면으로 이동
        Navigator.pushReplacementNamed(context, '/main_screen');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Social Login")),
      body: Center(
        child: Consumer<UserController>(
          builder: (context, controller, child) {
            final isLoggedIn = controller.user != null || controller.googleUser != null;

            if (isLoggedIn) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _checkProfile(context));
              return const CircularProgressIndicator();
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: context.read<UserController>().kakaoLogin,
                  child: Image.asset("assets/img/kakao_login_medium_narrow.png"),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: context.read<UserController>().googleLogin,
                  child: Image.asset("assets/img/google.png"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
