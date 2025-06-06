import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runrun/services/firebase_record.dart';
import 'package:runrun/models/running_record.dart';
import 'package:runrun/controllers/user_controller.dart';

class ActivityScreen extends StatefulWidget {
  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final FirebaseRecordService _firebaseService = FirebaseRecordService();
  String _selectedFilter = "전체"; // 기본 필터
  List<RunningRecord> _records = []; // 활동 기록 저장

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<UserController>().userId;

    return Scaffold(
      appBar: AppBar(
        title: Text('활동'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 상단 필터 버튼
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterButton("주"),
                _buildFilterButton("월"),
                _buildFilterButton("년"),
                _buildFilterButton("전체"),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1),

          // 통계 표시
          FutureBuilder<List<RunningRecord>>(
            future: _fetchFilteredRecords(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Expanded(
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Expanded(
                  child: Center(child: Text('오류 발생: ${snapshot.error}')),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Expanded(
                  child: Center(child: Text('활동 기록이 없습니다.')),
                );
              }

              _records = snapshot.data!;
              return Expanded(child: _buildStats(_records));
            },
          ),
        ],
      ),
    );
  }

  /// 필터 버튼 빌드
  Widget _buildFilterButton(String label) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = label;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedFilter == label ? Colors.blue : Colors.grey[300],
        foregroundColor: _selectedFilter == label ? Colors.white : Colors.black,
      ),
      child: Text(label, style: TextStyle(fontSize: 16)),
    );
  }

  /// 필터에 따른 기록 가져오기
  Future<List<RunningRecord>> _fetchFilteredRecords(String userId) async {
    switch (_selectedFilter) {
      case "주":
        return await _firebaseService.getWeeklyRecords(userId);
      case "월":
        return await _firebaseService.getMonthlyRecords(userId);
      case "년":
        return await _firebaseService.getYearlyRecords(userId);
      default:
        return await _firebaseService.getAllRecords(userId);
    }
  }

  /// 통계 섹션
  Widget _buildStats(List<RunningRecord> records) {
    final totalDistance = records.fold(0.0, (sum, r) => sum + r.distance);
    final totalTime = records.fold(0, (sum, r) => sum + r.time);
    final totalCalories = records.fold(0.0, (sum, r) => sum + r.kcal);
    final runCount = records.length;

    return Column(
      children: [
        _buildStatCard("총 거리", '${totalDistance.toStringAsFixed(2)} km'),
        _buildStatCard("러닝 횟수", '$runCount'),
        _buildStatCard("총 소모 칼로리", '${totalCalories.toStringAsFixed(1)} kcal'),
        _buildStatCard("총 시간", _formatDuration(Duration(seconds: totalTime))),
      ],
    );
  }

  /// 통계 카드 빌드
  Widget _buildStatCard(String label, String value) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  /// Duration 형식 변환
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inHours)}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }
}
