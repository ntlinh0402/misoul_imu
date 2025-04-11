// home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:misoul_imu/screens/imu_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _username = '';
  String _userType = '';
  List<Map<String, dynamic>> _connections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Lấy thông tin người dùng hiện tại
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        _username = userData['username'] ?? 'Người dùng';
        _userType = userData['userType'] ?? 'unknown';
      });

      // Lấy danh sách kết nối
      if (_userType == 'patient') {
        // Nếu là bệnh nhân, lấy danh sách người thân đã kết nối
        var connectionsSnapshot = await _firestore
            .collection('connections')
            .where('patientId', isEqualTo: _auth.currentUser!.uid)
            .get();

        List<Map<String, dynamic>> caregivers = [];
        for (var doc in connectionsSnapshot.docs) {
          String caregiverId = doc['caregiverId'];
          DocumentSnapshot caregiverDoc = await _firestore
              .collection('users')
              .doc(caregiverId)
              .get();

          if (caregiverDoc.exists) {
            Map<String, dynamic> caregiverData = caregiverDoc.data() as Map<String, dynamic>;
            caregivers.add({
              'id': caregiverId,
              'username': caregiverData['username'] ?? 'Người thân',
              'connectionId': doc.id,
            });
          }
        }

        setState(() {
          _connections = caregivers;
          _isLoading = false;
        });
      } else if (_userType == 'caregiver') {
        // Nếu là người thân, lấy danh sách bệnh nhân đã kết nối
        var connectionsSnapshot = await _firestore
            .collection('connections')
            .where('caregiverId', isEqualTo: _auth.currentUser!.uid)
            .get();

        List<Map<String, dynamic>> patients = [];
        for (var doc in connectionsSnapshot.docs) {
          String patientId = doc['patientId'];
          DocumentSnapshot patientDoc = await _firestore
              .collection('users')
              .doc(patientId)
              .get();

          if (patientDoc.exists) {
            Map<String, dynamic> patientData = patientDoc.data() as Map<String, dynamic>;
            patients.add({
              'id': patientId,
              'username': patientData['username'] ?? 'Bệnh nhân',
              'connectionId': doc.id,
            });
          }
        }

        setState(() {
          _connections = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Lỗi khi tải dữ liệu người dùng: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'MISOUL',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Header with user info
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFFFEEF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào, $_username',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _userType == 'patient'
                      ? 'Người được chăm sóc'
                      : 'Người chăm sóc',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          // Connections section title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  _userType == 'patient'
                      ? 'Người thân của bạn'
                      : 'Người bạn chăm sóc',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Color(0xFFE91E63)),
                  onPressed: () {
                    // Hiển thị dialog để thêm kết nối mới
                    _showAddConnectionDialog();
                  },
                ),
              ],
            ),
          ),

          // List of connections
          Expanded(
            child: _connections.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Bạn chưa có kết nối nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      _showAddConnectionDialog();
                    },
                    child: Text('Thêm kết nối mới'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE91E63),
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _connections.length,
              itemBuilder: (context, index) {
                final connection = _connections[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Color(0xFFFFCDD2),
                      child: Icon(
                        Icons.person,
                        color: Color(0xFFE91E63),
                      ),
                    ),
                    title: Text(
                      connection['username'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _userType == 'patient'
                          ? 'Người thân của bạn'
                          : 'Bạn đang chăm sóc',
                    ),
                    trailing: _userType == 'caregiver'
                        ? ElevatedButton(
                      onPressed: () {
                        // Mở màn hình IMU với người này
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => IMUScreen(
                              username: connection['username'],
                              receiverId: connection['id'],
                            ),
                          ),
                        );
                      },
                      child: Icon(Icons.favorite, color: Colors.white),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFE91E63),
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(12),
                      ),
                    )
                        : null,
                    onTap: () {
                      // Hiển thị chi tiết kết nối
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddConnectionDialog() {
    final TextEditingController _codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thêm kết nối mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_userType == 'patient')
              Text(
                'Mã kết nối của bạn: ${_auth.currentUser!.uid.substring(0, 8)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (_userType == 'patient')
              Text(
                'Chia sẻ mã này cho người thân để họ có thể kết nối với bạn.',
                style: TextStyle(fontSize: 12),
              ),
            if (_userType == 'patient') SizedBox(height: 16),
            if (_userType == 'caregiver')
              TextField(
                controller: _codeController,
                decoration: InputDecoration(
                  labelText: 'Nhập mã kết nối',
                  hintText: 'Nhập mã kết nối từ người cần chăm sóc',
                  border: OutlineInputBorder(),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Đóng'),
          ),
          if (_userType == 'caregiver')
            ElevatedButton(
              onPressed: () async {
                // Xử lý thêm kết nối
                String connectionCode = _codeController.text.trim();
                if (connectionCode.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vui lòng nhập mã kết nối')),
                  );
                  return;
                }

                try {
                  // Tìm người dùng với mã kết nối (8 ký tự đầu tiên của user ID)
                  QuerySnapshot userQuery = await _firestore
                      .collection('users')
                      .where('userType', isEqualTo: 'patient')
                      .get();

                  String? patientId;
                  for (var doc in userQuery.docs) {
                    if (doc.id.substring(0, 8) == connectionCode) {
                      patientId = doc.id;
                      break;
                    }
                  }

                  if (patientId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Không tìm thấy người dùng với mã kết nối này')),
                    );
                    Navigator.of(context).pop();
                    return;
                  }

                  // Kiểm tra xem kết nối đã tồn tại chưa
                  QuerySnapshot existingConnection = await _firestore
                      .collection('connections')
                      .where('patientId', isEqualTo: patientId)
                      .where('caregiverId', isEqualTo: _auth.currentUser!.uid)
                      .get();

                  if (existingConnection.docs.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Kết nối này đã tồn tại')),
                    );
                    Navigator.of(context).pop();
                    return;
                  }

                  // Tạo kết nối mới
                  await _firestore.collection('connections').add({
                    'patientId': patientId,
                    'caregiverId': _auth.currentUser!.uid,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Thêm kết nối thành công')),
                  );
                  Navigator.of(context).pop();

                  // Làm mới dữ liệu
                  _loadUserData();
                } catch (e) {
                  print('Lỗi khi thêm kết nối: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã xảy ra lỗi. Vui lòng thử lại.')),
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Kết nối'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFE91E63),
              ),
            ),
        ],
      ),
    );
  }
}