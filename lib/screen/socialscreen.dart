import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:runrun/controllers/user_controller.dart';

//작동 원리
//앱이 실행되면 userId를 기준으로 사용자의 데이터를 Firebase에서 가져옴.
//사용자가 이름을 입력해 검색하면 Firestore에서 쿼리를 실행하여 결과를 보여줌.
//친구 요청을 보내거나 수락/거절 시 Firestore 데이터가 실시간으로 업데이트.
//친구 목록에서 친구 항목을 클릭하면 해당 친구의 상세 정보가 Dialog로 표시.
//실시간 업데이트: StreamBuilder를 사용하여 데이터가 변경되면 즉시 UI에 반영.


class SocialScreen extends StatefulWidget {
  const SocialScreen({Key? key}) : super(key: key);

  @override
  _SocialScreenState createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _searchResults = [];

  /// 친구 검색
  Future<void> _searchUsers(String query) async {
    final userController = context.read<UserController>();
    final userId = userController.userId;

    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    setState(() {
      _searchResults.clear();
      _searchResults.addAll(result.docs.where((doc) => doc.id != userId).map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'],
          'profile_image': data['profile_image'],
        };
      }).toList());
    });
  }

  /// 친구 요청 보내기
  Future<void> _sendFriendRequest(String senderId, String friendId) async {
    if (senderId == friendId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('본인에게 친구 요청을 보낼 수 없습니다.')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('friend_requests')
          .doc(senderId)
          .set({
        'senderId': senderId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 요청을 보냈습니다!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 요청을 보내는 데 실패했습니다.')),
      );
    }
  }

  /// 친구 요청 거절하기
  Future<void> _rejectFriendRequest(String userId, String friendId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friend_requests')
          .doc(friendId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 요청을 거절했습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 요청을 거절하는 데 실패했습니다.')),
      );
    }
  }

  /// 친구 요청 수락하기
  Future<void> _acceptFriendRequest(String userId, String friendId) async {
    try {
      // 친구 목록에 추가
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .doc(friendId)
          .set({'friendId': friendId});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(friendId)
          .collection('friends')
          .doc(userId)
          .set({'friendId': userId});

      // 친구 요청 삭제
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friend_requests')
          .doc(friendId)
          .delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 요청을 수락했습니다!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('친구 요청을 수락하는 데 실패했습니다.')),
      );
    }
  }

  /// 친구의 정보 보기
  void _viewFriendDetails(String friendId) async {
    final friendData = await FirebaseFirestore.instance
        .collection('users')
        .doc(friendId)
        .get();

    if (friendData.exists) {
      final data = friendData.data()!;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(data['name'] ?? 'Unknown'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data['profile_image'] != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(data['profile_image']),
                    radius: 40,
                  ),
                const SizedBox(height: 16),
                Text('총 뛴 거리: ${data['total_km'] ?? 0} km'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기'),
              ),
            ],
          );
        },
      );
    }
  }

  /// 친구 요청 표시
  Widget _friendRequests(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friend_requests')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('받은 친구 요청이 없습니다.'));
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final senderId = request['senderId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(senderId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final senderData = snapshot.data!.data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: senderData['profile_image'] != null
                        ? NetworkImage(senderData['profile_image'])
                        : null,
                  ),
                  title: Text(senderData['name'] ?? 'Unknown'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            _acceptFriendRequest(userId, senderId),
                        child: const Text('수락'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () =>
                            _rejectFriendRequest(userId, senderId),
                        child: const Text('거절'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// 친구 목록 표시
  Widget _friendList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('friends')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('추가된 친구가 없습니다.'));
        }

        final friends = snapshot.data!.docs;

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {
            final friendId = friends[index]['friendId'];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendId)
                  .get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final friendData = snapshot.data!.data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: friendData['profile_image'] != null
                        ? NetworkImage(friendData['profile_image'])
                        : null,
                  ),
                  title: Text(friendData['name'] ?? 'Unknown'),
                  onTap: () => _viewFriendDetails(friendId),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userController = context.watch<UserController>();
    final userId = userController.userId;
    final userName = userController.user?.properties?['nickname'] ??
        userController.googleUser?.displayName ??
        'Unknown User';
    final profileImage = userController.user?.properties?['profile_image'] ??
        userController.googleUser?.photoUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Social')),
      body: Column(
        children: [
          // 프로필 영역
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                  profileImage != null ? NetworkImage(profileImage) : null,
                  child: profileImage == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () async {
                          await userController.logout();
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        child: const Text('로그아웃'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1), // 구분선
          // 친구 추가 (검색) 섹션
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    labelText: '친구 이름 검색',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _searchUsers(_searchController.text),
                  child: const Text('검색'),
                ),
              ],
            ),
          ),
          // 검색 결과
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    title: Text(user['name']),
                    leading: CircleAvatar(
                      backgroundImage: user['profile_image'] != null
                          ? NetworkImage(user['profile_image'])
                          : null,
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _sendFriendRequest(userId, user['id']),
                      child: const Text('친구 요청'),
                    ),
                  );
                },
              ),
            ),
          const Divider(thickness: 1), // 구분선
          // 친구 요청 및 친구 목록
          Expanded(
            child: Column(
              children: [
                Expanded(child: _friendRequests(userId)),
                const Divider(thickness: 1),
                Expanded(child: _friendList(userId)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
