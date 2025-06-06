import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:runrun/models/running_record.dart';

class FirebaseRecordService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 사용자 활동 기록 스트림 가져오기
  Stream<List<RunningRecord>> streamActivityLogsForUser(String userId) {
    return _firestore
        .collection('activity_logs')
        .where('user_id', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs.map((doc) {
        return RunningRecord.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<List<RunningRecord>> getRunningLogsForDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day); // 선택한 날짜의 시작
      final endOfDay = startOfDay.add(Duration(days: 1)); // 다음 날의 시작

      final snapshot = await FirebaseFirestore.instance
          .collection('activity_logs')
          .where('user_id', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => RunningRecord.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print("Error fetching daily logs: $e");
      return [];
    }
  }


  /// 활동 기록 삭제
  Future<void> deleteActivityLog(String recordId, double distance, String userId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        // 활동 기록 삭제
        transaction.delete(_firestore.collection('activity_logs').doc(recordId));
        // 누적 거리 업데이트
        transaction.update(userDoc, {
          "total_km": FieldValue.increment(-distance),
        });
      });
    } catch (e) {
      print("Error deleting activity log: $e");
      rethrow;
    }
  }

  /// 새 활동 기록 추가
  Future<void> addRunningRecord(String userId, RunningRecord record) async {
    try {
      final activityLogsCollection = _firestore.collection('activity_logs');
      final userDoc = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        // 활동 기록 추가
        transaction.set(activityLogsCollection.doc(), {
          ...record.toMap(),
          'user_id': userId,
        });
        // 누적 거리 업데이트
        transaction.update(userDoc, {
          "total_km": FieldValue.increment(record.distance),
        });
      });
    } catch (e) {
      print("Error adding running record: $e");
      rethrow;
    }
  }

  /// 사용자 누적 거리 가져오기
  Future<double> getTotalKm(String userId) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final snapshot = await userDoc.get();

      if (snapshot.exists) {
        return snapshot.data()?['total_km'] ?? 0.0;
      } else {
        return 0.0;
      }
    } catch (e) {
      print("Error getting total km: $e");
      return 0.0;
    }
  }

  /// 사용자 누적 거리 실시간 스트림
  Stream<double> streamTotalKm(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data()?['total_km'] ?? 0.0;
      } else {
        return 0.0;
      }
    });
  }
  Future<List<RunningRecord>> getWeeklyRecords(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(Duration(days: 6));

    return _firestore
        .collection('activity_logs')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfWeek)
        .where('date', isLessThanOrEqualTo: endOfWeek)
        .get()
        .then((snapshot) => snapshot.docs.map((doc) => RunningRecord.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<RunningRecord>> getMonthlyRecords(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return _firestore
        .collection('activity_logs')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .get()
        .then((snapshot) => snapshot.docs.map((doc) => RunningRecord.fromMap(doc.data(), doc.id)).toList());
  }

  Future<List<RunningRecord>> getYearlyRecords(String userId) async {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year + 1, 1, 0);

    return _firestore
        .collection('activity_logs')
        .where('user_id', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: startOfYear)
        .where('date', isLessThanOrEqualTo: endOfYear)
        .get()
        .then((snapshot) => snapshot.docs.map((doc) => RunningRecord.fromMap(doc.data(), doc.id)).toList());
  }
  Future<List<RunningRecord>> getAllRecords(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('activity_logs')
          .where('user_id', isEqualTo: userId) // 특정 사용자의 데이터만 가져옴
          .orderBy('date', descending: true) // 최신 데이터 순서대로 정렬
          .get();

      return snapshot.docs
          .map((doc) => RunningRecord.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("Error fetching all records: $e");
      return [];
    }
  }



}


