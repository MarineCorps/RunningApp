import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runrun/controllers/user_controller.dart'; // 로그인 상태를 가져오기 위해 추가
import 'package:runrun/services/firebase_record.dart';

class CharacterScreen extends StatefulWidget {
  final String userid; // 사용자 ID를 받는 변수

  const CharacterScreen({Key? key, required this.userid}) : super(key: key);
  @override
  _CharacterScreenState createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  int headIndex = 0; // 머리 의상
  int clothingIndex = 0; // 옷 의상 (0 = 아무것도 안 입은 상태)
  double totalKm = 0.0; // Firebase에서 가져온 누적 거리
  int bodyIndex = 0; // km 기반 체형 인덱스
  double nextGoalKm = 30.0; // 초기 목표 거리

  final FirebaseRecordService _firebaseService = FirebaseRecordService();

  final List<Map<String, dynamic>> headData = [
    {"path": 'assets/img/default_face.png', "requiredKm": 0}, // 기본 상태
    {"path": 'assets/img/default_hat1.png', "requiredKm": 0},
    {"path": 'assets/img/default_hat2.png', "requiredKm": 0},
    {"path": 'assets/img/default_hat3.png', "requiredKm": 0},
    {"path": 'assets/img/low_hat.png', "requiredKm": 30}, // 30km 달성 시 지급
    {"path": 'assets/img/middle_hat.png', "requiredKm": 60}, // 60km 달성 시 지급
    {"path": 'assets/img/luxury_hat.png', "requiredKm": 80}, // 80km 달성 시 지급
  ];

  final List<Map<String, dynamic>> clothingData = [
    {"path": '', "requiredKm": 0}, // 기본 상태 (잠금 없음)
    {"path": 'assets/img/first2.png', "requiredKm": 30}, // 돼지 탈출 시 지급
    {"path": 'assets/img/first3.png', "requiredKm": 30},
    {"path": 'assets/img/low1.png', "requiredKm": 50}, // 중간거의 도달 시 지급
    {"path": 'assets/img/low2.png', "requiredKm": 50},
    {"path": 'assets/img/middle1.png', "requiredKm": 60}, // 근육맨 되면 지급
    {"path": 'assets/img/middle2.png', "requiredKm": 60},
    {"path": 'assets/img/middle3.png', "requiredKm": 60},
    {"path": 'assets/img/luxury1.png', "requiredKm": 80}, // 많이 뛰면 지급
    {"path": 'assets/img/luxury2.png', "requiredKm": 80},
  ];

  final List<String> bodyImages = [
    'assets/img/fat.png', // 돼지
    'assets/img/normal.png', // 중간
    'assets/img/muscle.png', // 근육
  ];

  @override
  void initState() {
    super.initState();
    _fetchTotalKm();
  }

  Future<void> _fetchTotalKm() async {
    final userId = context.read<UserController>().userId; // 로그인된 사용자의 ID
    final km = await _firebaseService.getTotalKm(userId);
    setState(() {
      totalKm = km;
      bodyIndex = _getBodyIndex(totalKm); // km에 따라 체형 결정
      nextGoalKm = _getNextGoal(totalKm); // 다음 목표 설정
    });
  }

  int _getBodyIndex(double km) {
    if (km < 30) {
      return 0; // 돼지 체형
    } else if (km < 60) {
      return 1; // 중간 체형
    } else {
      return 2; // 근육 체형
    }
  }

  double _getNextGoal(double km) {
    if (km < 30) {
      return 30.0; // 돼지에서 중간 목표
    } else if (km < 60) {
      return 60.0; // 중간에서 근육 목표
    } else {
      return 0.0; // 목표 없음
    }
  }

  String _getCurrentState(double km) {
    if (km < 30) {
      return "돼지"; // 돼지 상태
    } else if (km < 60) {
      return "보통"; // 중간 상태
    } else {
      return "근육질"; // 근육 상태
    }
  }

  String _getMotivationalMessage(double km) {
    if (km < 30) {
      return "빨리 뛰십쇼";
    } else if (km < 60) {
      return "조금만 더 뛰십쇼";
    } else {
      return "마음대로 뛰십쇼";
    }
  }

  void changeHead(int direction) {
    setState(() {
      do {
        headIndex = (headIndex + direction) % headData.length;
        if (headIndex < 0) headIndex = headData.length - 1;
      } while (headData[headIndex]["requiredKm"] > totalKm);
    });
  }

  void changeClothing(int direction) {
    setState(() {
      do {
        clothingIndex = (clothingIndex + direction) % clothingData.length;
        if (clothingIndex < 0) clothingIndex = clothingData.length - 1;
      } while (clothingData[clothingIndex]["requiredKm"] > totalKm);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isPigState = _getCurrentState(totalKm) == "돼지"; // 돼지 상태인지 확인

    return Scaffold(
      appBar: AppBar(
        title: Text('Character Screen'),
      ),
      body: Column(
        children: [
          // 상단 거리 텍스트
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              nextGoalKm > 0
                  ? "현재: ${totalKm.toStringAsFixed(1)}km / 목표: ${nextGoalKm.toStringAsFixed(1)}km"
                  : "현재: ${totalKm.toStringAsFixed(1)}km",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          // 동기부여 메시지
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              _getMotivationalMessage(totalKm),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 몸통 이미지
                Positioned(
                  top: screenHeight * 0.195,
                  child: Image.asset(
                    bodyImages[bodyIndex],
                    width: screenWidth * 0.5,
                    height: screenHeight * 0.37,
                    fit: BoxFit.contain,
                  ),
                ),
                // 머리 이미지 (몸통 살짝 덮음)
                Positioned(
                  top: screenHeight * 0.135,
                  child: Image.asset(
                    headData[headIndex]["path"],
                    width: screenWidth * 0.3,
                    height: screenHeight * 0.2,
                    fit: BoxFit.contain,
                  ),
                ),
                // 옷 이미지
                if (clothingIndex > 0 &&
                    clothingData[clothingIndex]["requiredKm"] <= totalKm)
                  Positioned(
                    top: screenHeight * 0.193,
                    child: Image.asset(
                      clothingData[clothingIndex]["path"],
                      width: screenWidth * 0.5,
                      height: screenHeight * 0.37,
                      fit: BoxFit.contain,
                    ),
                  ),
                // 머리 변경 버튼
                Positioned(
                  top: screenHeight * 0.2,
                  left: screenWidth * 0.05,
                  child: IconButton(
                    icon: Icon(Icons.arrow_left, size: 40),
                    onPressed: () => changeHead(-1),
                  ),
                ),
                Positioned(
                  top: screenHeight * 0.2,
                  right: screenWidth * 0.05,
                  child: IconButton(
                    icon: Icon(Icons.arrow_right, size: 40),
                    onPressed: () => changeHead(1),
                  ),
                ),
                // 옷 변경 버튼
                Positioned(
                  top: screenHeight * 0.45,
                  left: screenWidth * 0.05,
                  child: IconButton(
                    icon: Icon(Icons.arrow_left, size: 40),
                    onPressed: isPigState ? null : () => changeClothing(-1),
                  ),
                ),
                Positioned(
                  top: screenHeight * 0.45,
                  right: screenWidth * 0.05,
                  child: IconButton(
                    icon: Icon(Icons.arrow_right, size: 40),
                    onPressed: isPigState ? null : () => changeClothing(1),
                  ),
                ),
              ],
            ),
          ),
          // 하단 상태 텍스트
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "현재 상태: ${_getCurrentState(totalKm)}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
