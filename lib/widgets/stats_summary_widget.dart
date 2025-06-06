import 'package:flutter/material.dart';

class StatsSummaryWidget extends StatelessWidget {
  final double totalDistance;
  final double totalTime;
  final double averagePace;

  const StatsSummaryWidget({
    Key? key,
    required this.totalDistance,
    required this.totalTime,
    required this.averagePace,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("${totalDistance.toStringAsFixed(2)} km", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        Text("평균 페이스: ${averagePace.toStringAsFixed(2)} 분/km"),
        Text("시간: ${_formatTime(totalTime)}"),
      ],
    );
  }

  String _formatTime(double seconds) {
    int minutes = (seconds ~/ 60);
    int remainingSeconds = (seconds % 60).toInt();
    return "$minutes분 $remainingSeconds초";
  }
}
