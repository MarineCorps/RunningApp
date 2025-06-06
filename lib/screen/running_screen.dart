import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:runrun/controllers/user_controller.dart';

class RunningScreen extends StatefulWidget {
  @override
  _RunningScreenState createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];
  double _totalDistance = 0.0;
  Timer? _timer;
  int _elapsedTime = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  StreamSubscription<Position>? _positionStream;
  double _caloriesBurned = 0.0;

  @override
  void initState() {
    super.initState();
    _startLocationService();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startLocationService() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _routePoints.add(_currentPosition!); // 시작 위치를 경로에 추가
    });
    _startPositionStream();
  }

  void _startPositionStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // 최소 5m 이동마다 위치 업데이트
      ),
    ).listen((Position position) {
      _updateLocation(position);
    });
  }

  void _stopPositionStream() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  void _updateLocation(Position position) {
    LatLng newPosition = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentPosition = newPosition;
      _routePoints.add(newPosition);

      if (_routePoints.length > 1) {
        double distance = Geolocator.distanceBetween(
          _routePoints[_routePoints.length - 2].latitude,
          _routePoints[_routePoints.length - 2].longitude,
          newPosition.latitude,
          newPosition.longitude,
        );
        _totalDistance += distance;
      }

      _caloriesBurned = _calculateCalories(_totalDistance, _elapsedTime);

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(newPosition),
        );
      }
    });
  }

  void _startRunning() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedTime++;
        });
      }
    });
  }

  void _pauseRunning() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stopRunning() {
    setState(() {
      _isRunning = false;
    });

    _timer?.cancel();
    _stopPositionStream();
    _uploadDataToFirebase();
    _showResultsDialog();
  }

  double _calculateCalories(double distance, int elapsedTime) {
    double weight = 70.0; // Assume weight is 70kg
    double met = 9.0; // MET value for running
    double hours = elapsedTime / 3600.0;
    return weight * met * hours;
  }

  double _calculatePace() {
    return _totalDistance > 0 ? _elapsedTime / (_totalDistance / 1000) : 0;
  }

  Future<void> _uploadDataToFirebase() async {
    final email = context.read<UserController>().googleUser?.email ??
        context.read<UserController>().user?.kakaoAccount?.email ??
        "unknown_user";

    DateTime now = DateTime.now();
    String dayOfWeek = [
      "월요일",
      "화요일",
      "수요일",
      "목요일",
      "금요일",
      "토요일",
      "일요일"
    ][now.weekday - 1];

    String type = now.hour >= 18 ? "야간 러닝" : "주간 러닝";

    Map<String, dynamic> data = {
      "user_id": email,
      "date": Timestamp.fromDate(now),
      "distance": (_totalDistance / 1000).toStringAsFixed(2),
      "pace": _calculatePace().toStringAsFixed(2),
      "time": _elapsedTime,
      "kcal": _caloriesBurned.toStringAsFixed(2),
      "type": "$dayOfWeek $type",
    };

    try {
      await FirebaseFirestore.instance.collection("activity_logs").add(data);
      print("러닝 데이터가 성공적으로 저장되었습니다!");
    } catch (e) {
      print("파이어베이스 업로드 중 오류 발생: $e");
    }
  }

  void _showResultsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('러닝 결과'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('총 거리: ${(this._totalDistance / 1000).toStringAsFixed(2)} km'),
              Text('총 시간: ${(_elapsedTime ~/ 60).toString().padLeft(2, '0')}:${(_elapsedTime % 60).toString().padLeft(2, '0')}'),
              Text('평균 페이스: ${_calculatePace().toStringAsFixed(2)} 분/킬로'),
              Text('소모 칼로리: ${_caloriesBurned.toStringAsFixed(2)} kcal'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Marker _buildCurrentLocationMarker() {
    if (_currentPosition == null) return Marker(markerId: MarkerId('empty'));
    return Marker(
      markerId: MarkerId('currentLocation'),
      position: _currentPosition!,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    );
  }

  Polyline _buildRoutePolyline() {
    return Polyline(
      polylineId: PolylineId('route'),
      points: _routePoints,
      color: Colors.blue,
      width: 5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('러닝'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? LatLng(37.7749, -122.4194),
              zoom: 16.0,
            ),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            markers: {
              if (_currentPosition != null) _buildCurrentLocationMarker(),
            },
            polylines: {
              if (_routePoints.isNotEmpty) _buildRoutePolyline(),
            },
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton.extended(
                      onPressed: _isRunning ? _pauseRunning : _startRunning,
                      backgroundColor: Colors.yellow,
                      label: Text(_isRunning
                          ? (_isPaused ? '계속' : '일시정지')
                          : '시작'),
                    ),
                    SizedBox(width: 20),
                    if (_isRunning)
                      FloatingActionButton.extended(
                        onPressed: _stopRunning,
                        backgroundColor: Colors.red,
                        label: Text('중지'),
                      ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(20),
                  color: Colors.white,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text('${(_totalDistance / 1000).toStringAsFixed(2)}'),
                              Text('km'),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                '${(_elapsedTime ~/ 60).toString().padLeft(2, '0')}:${(_elapsedTime % 60).toString().padLeft(2, '0')}',
                              ),
                              Text('시간'),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text('${_calculatePace().toStringAsFixed(2)}'),
                              Text('분/킬로'),
                            ],
                          ),
                          Column(
                            children: [
                              Text('${_caloriesBurned.toStringAsFixed(2)}'),
                              Text('kcal'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
