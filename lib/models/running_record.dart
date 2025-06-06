import 'package:cloud_firestore/cloud_firestore.dart';

class RunningRecord {
  final String? id; // Firebase 문서 ID
  final DateTime date;
  final double distance;
  final double pace;
  final int time;
  final double kcal;
  final String type;

  RunningRecord({
    this.id,
    required this.date,
    required this.distance,
    required this.pace,
    required this.time,
    required this.kcal,
    required this.type,
  });

  // 데이터를 Firestore 형식으로 변환
  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date), // DateTime -> Timestamp 변환
      'distance': distance,
      'pace': pace,
      'time': time,
      'kcal': kcal,
      'type': type,
    };
  }

  // Firestore 데이터에서 객체로 변환
  static RunningRecord fromMap(Map<String, dynamic> map, String id) {
    return RunningRecord(
      id: id,
      date: (map['date'] as Timestamp).toDate(), // Timestamp -> DateTime 변환
      distance: double.tryParse(map['distance'].toString()) ?? 0.0, // 문자열 또는 숫자를 double로 변환
      pace: double.tryParse(map['pace'].toString()) ?? 0.0, // 문자열 또는 숫자를 double로 변환
      time: map['time'] is int
          ? map['time'] // 이미 int 타입이면 그대로 사용
          : int.tryParse(map['time'].toString()) ?? 0, // 문자열을 int로 변환
      kcal: double.tryParse(map['kcal'].toString()) ?? 0.0, // 문자열 또는 숫자를 double로 변환
      type: map['type'] ?? '', // 문자열 값이 없으면 기본값 ''
    );
  }
}
