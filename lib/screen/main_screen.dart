import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runrun/screen/homescreen.dart';
import 'package:runrun/screen/characterscreen.dart';
import 'package:runrun/screen/socialscreen.dart';
import 'package:runrun/controllers/user_controller.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; // 현재 선택된 탭의 인덱스
  final PageController _pageController = PageController(); // PageView 컨트롤러

  // 페이지가 변경될 때 호출
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // 탭이 선택될 때 호출
  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300), // 애니메이션 지속 시간
      curve: Curves.easeInOut, // 애니메이션 커브
    );
  }

  @override
  void dispose() {
    _pageController.dispose(); // PageController 메모리 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UserController를 통해 현재 로그인된 사용자 정보를 얻음
    final userId = context.watch<UserController>().userId;

    return Scaffold(
      body: PageView(
        controller: _pageController, // PageController 연결
        onPageChanged: _onPageChanged, // 페이지 변경 시 호출
        children: [
          HomeScreen(userid: userId), // 사용자 ID를 전달
          CharacterScreen(userid: userId), // 사용자 ID를 전달
          SocialScreen(), // 소셜 화면
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // 현재 선택된 탭
        onTap: _onTabTapped, // 탭 선택 시 호출
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Home'), // 홈 탭
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Character'), // 캐릭터 탭
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Social'), // 소셜 탭
        ],
      ),
    );
  }
}
