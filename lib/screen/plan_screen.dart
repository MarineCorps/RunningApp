import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:runrun/services/firebase_record.dart';
import 'package:runrun/models/running_record.dart';
import 'package:provider/provider.dart';
import 'package:runrun/controllers/user_controller.dart';

class PlanScreen extends StatefulWidget {
  @override
  _PlanScreenState createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  DateTime _selectedDate = DateTime.now(); // 선택된 날짜
  List<RunningRecord> _dailyLogs = []; // 선택된 날짜의 러닝 기록 저장
  final FirebaseRecordService _firebaseService = FirebaseRecordService();

  @override
  void initState() {
    super.initState();
    _fetchDailyLogs(_selectedDate); // 초기 선택된 날짜의 기록 가져오기
  }

  /// 선택된 날짜의 러닝 기록 가져오기
  Future<void> _fetchDailyLogs(DateTime date) async {
    final userId = context.read<UserController>().userId; // 로그인된 사용자 ID 가져오기
    final logs = await _firebaseService.getRunningLogsForDate(userId, date);
    setState(() {
      _dailyLogs = logs;
    });
  }

  /// Firebase에서 기록 삭제
  Future<void> _deleteRecord(RunningRecord record) async {
    final userId = context.read<UserController>().userId;
    try {
      await _firebaseService.deleteActivityLog(record.id!, record.distance, userId);
      setState(() {
        _dailyLogs.remove(record);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('기록이 삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('기록 삭제 중 오류가 발생했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('플랜'),
      ),
      body: Column(
        children: [
          // 달력 위젯
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
              });
              _fetchDailyLogs(selectedDay); // 선택된 날짜의 기록 가져오기
            },
          ),
          const Divider(height: 1, thickness: 1), // 구분선
          // 선택된 날짜의 기록 표시
          Expanded(
            child: _dailyLogs.isEmpty
                ? Center(
              child: Text(
                '선택된 날짜에 기록이 없습니다.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _dailyLogs.length,
              itemBuilder: (context, index) {
                final record = _dailyLogs[index];
                return Dismissible(
                  key: Key(record.id!), // Firebase의 기록 ID를 키로 사용
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteRecord(record); // 기록 삭제 처리
                  },
                  child: ListTile(
                    title: Text(
                      "거리: ${record.distance.toStringAsFixed(1)}km",
                    ),
                    subtitle: Text(
                      "시간: ${Duration(seconds: record.time)} / 칼로리: ${record.kcal.toStringAsFixed(1)}kcal",
                    ),
                    trailing: Text(
                      record.type ?? "러닝",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
