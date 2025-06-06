import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:runrun/services/firebase_record.dart';
import 'package:runrun/models/running_record.dart';
import 'package:runrun/screen/plan_screen.dart';
import 'package:runrun/screen/activity_screen.dart';
import 'package:runrun/screen/running_screen.dart';
import 'package:runrun/controllers/user_controller.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  final String userid; // 사용자 ID를 받는 변수

  const HomeScreen({Key? key, required this.userid}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  final FirebaseRecordService _firebaseService = FirebaseRecordService();

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  /// Fetches the current location of the user
  Future<void> _initializeLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 서비스를 활성화해주세요.')),
      );
      return;
    }

    // Check for location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 권한이 필요합니다.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.')),
      );
      return;
    }

    // Fetch current position
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(_currentPosition!),
        );
      }
    } catch (e) {
      print('Error fetching current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('현재 위치를 가져올 수 없습니다.')),
      );
    }
  }

  /// 테스트데이터추가
  Future<void> _addTestData(String userId) async {
    final random = Random();

    try {
      // Create a test record with fixed and random values
      final record = RunningRecord(
        date: DateTime.now(),
        distance: 10.0, // 고정 거리
        pace: random.nextDouble() * 6 + 4, // 4~10 km/h 임의 값
        time: random.nextInt(3600) + 600, // 10~70분 임의 값
        kcal: random.nextDouble() * 300 + 200, // 200~500 kcal 임의 값
        type: random.nextBool() ? "주간 러닝" : "야간 러닝", // 러닝 유형
      );

      // Add the test data to Firestore
      await _firebaseService.addRunningRecord(userId, record);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('테스트 데이터가 추가되었습니다!')),
      );
    } catch (e) {
      print('Error adding test data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('테스트 데이터 추가 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();
    final userName = userController.user?.properties?["nickname"] ??
        userController.googleUser?.displayName ??
        "사용자 이름";
    final userEmail = userController.user?.kakaoAccount?.email ??
        userController.googleUser?.email ??
        "사용자 이메일";
    final userProfile = userController.user?.properties?["profile_image"] ??
        userController.googleUser?.photoUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text('러닝'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              '러닝 가이드',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userName),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.grey,
                child: ClipOval(
                  child: userProfile != null
                      ? Image.network(userProfile, fit: BoxFit.cover)
                      : Icon(Icons.person, color: Colors.white, size: 40),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.directions_run),
              title: Text('러닝'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('기록'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PlanScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.bar_chart),
              title: Text('통계'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ActivityScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? LatLng(0, 0),
              zoom: 16.0,
            ),
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            markers: {
              if (_currentPosition != null)
                Marker(
                  markerId: MarkerId('currentPosition'),
                  position: _currentPosition!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
                ),
            },
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                SizedBox(height: 20),
                FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RunningScreen()),
                    );
                  },
                  backgroundColor: Colors.yellow,
                  label: Text(
                    '시작',
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => _addTestData(userController.userId),
                  child: Text('테스트 데이터 추가'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 4,
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
