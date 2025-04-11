import 'package:flutter/material.dart';
import 'package:misoul_imu/services/firebase_service.dart';
import 'package:misoul_imu/screens/imu_history_screen.dart';

class IMUScreen extends StatefulWidget {
  final String username;
  final String receiverId;

  const IMUScreen({
    Key? key,
    required this.username,
    required this.receiverId
  }) : super(key: key);

  @override
  State<IMUScreen> createState() => _IMUScreenState();
}

class _IMUScreenState extends State<IMUScreen> {
  int messageCount = 0;
  String moodStatus = 'BÌNH THƯỜNG';
  bool isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    _loadTodayMessageCount();
  }

  Future<void> _loadTodayMessageCount() async {
    try {
      final messages = await _firebaseService.getSentIMUMessages().first;
      final today = DateTime.now();
      final todayMessages = messages.where((msg) =>
      msg.sentAt.day == today.day &&
          msg.sentAt.month == today.month &&
          msg.sentAt.year == today.year
      );

      if (mounted) {
        setState(() {
          messageCount = todayMessages.length;
        });
      }
    } catch (e) {
      print('Error loading message count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Check icon at the top
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // I MISS U Title
                      const Text(
                        'I MISS U',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtitle
                      const Text(
                        'Bấm nút để gửi lời yêu thương tới\nngười thân của bạn',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      // Heart button
                      GestureDetector(
                        onTap: isLoading ? null : _sendIMUMessage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer circle
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFFC0CB).withOpacity(0.5),
                              ),
                            ),
                            // Inner circle
                            Container(
                              width: 150,
                              height: 150,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                            // Heart icon or loading indicator
                            isLoading
                                ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                            )
                                : const Icon(
                              Icons.favorite,
                              size: 80,
                              color: Color(0xFFE91E63),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Message count
                      Text(
                        'Hôm nay bạn đã gửi $messageCount lời yêu thương\ntới ${widget.username}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Mood status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'TÂM TRẠNG: ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getMoodIcon(),
                                  size: 16,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  moodStatus,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // History button
                      SizedBox(
                        width: 220,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => IMUHistoryScreen(username: widget.username),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            side: const BorderSide(color: Colors.black),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Xem lịch sử',
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMoodIcon() {
    switch (moodStatus.toUpperCase()) {
      case 'VUI VẺ':
        return Icons.sentiment_very_satisfied;
      case 'BUỒN':
        return Icons.sentiment_dissatisfied;
      case 'LO LẮNG':
        return Icons.sentiment_neutral;
      case 'CĂNG THẲNG':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_satisfied;
    }
  }

  Future<void> _sendIMUMessage() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      await _firebaseService.sendIMUMessage(
        receiverId: widget.receiverId,
        message: 'I miss you',
        type: 'imu',
      );

      if (mounted) {
        setState(() {
          messageCount++;
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lời yêu thương thành công!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      print('Error sending IMU message: $e');
    }
  }
}