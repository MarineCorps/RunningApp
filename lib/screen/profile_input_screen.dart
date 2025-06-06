import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileInputScreen extends StatefulWidget {
  final String userId; // 로그인한 사용자 ID

  const ProfileInputScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ProfileInputScreenState createState() => _ProfileInputScreenState();
}

class _ProfileInputScreenState extends State<ProfileInputScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  Future<void> _saveProfile() async {
    final height = double.tryParse(_heightController.text) ?? 0.0;
    final weight = double.tryParse(_weightController.text) ?? 0.0;

    if (height > 0 && weight > 0) {
      try {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(widget.userId);

        await userDoc.set({
          'height': height,
          'weight': weight,
        }, SetOptions(merge: true)); // 병합 저장

        // 입력 후 메인 화면으로 이동
        Navigator.pushReplacementNamed(context, '/main_screen');
      } catch (e) {
        print("프로필 저장 중 오류 발생: $e");
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('유효한 키와 몸무게를 입력하세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('키와 몸무게 입력')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '키 (cm)'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '몸무게 (kg)'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
