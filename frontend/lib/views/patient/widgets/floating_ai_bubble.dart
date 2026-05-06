import 'package:flutter/material.dart';
import '../ai_chat_screen.dart';

class FloatingAIBubble extends StatefulWidget {
  const FloatingAIBubble({super.key});

  @override
  State<FloatingAIBubble> createState() => _FloatingAIBubbleState();
}

class _FloatingAIBubbleState extends State<FloatingAIBubble> {
  // Biến lưu tọa độ của bong bóng trên màn hình
  double _x = 20; // Bắt đầu ở bên trái
  double _y = 0;
  bool _isInitialized = false;
  bool _isHover = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Khi màn hình vừa render, lấy chiều cao màn hình để đặt bong bóng ở góc DƯỚI BÊN TRÁI
    if (!_isInitialized) {
      final size = MediaQuery.of(context).size;
      _y =
          size.height -
          120; // Cách đáy 120px để không cấn thanh taskbar hoặc bottom nav
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const double bubbleSize = 70.0; // Kích thước bong bóng

    return Positioned(
      left: _x,
      top: _y,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHover = true),
        onExit: (_) => setState(() => _isHover = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          // --- XỬ LÝ KÉO THẢ (DRAG) ---
          onPanUpdate: (details) {
            setState(() {
              _x += details.delta.dx;
              _y += details.delta.dy;

              // Giới hạn để người dùng không kéo bong bóng văng ra khỏi màn hình
              if (_x < 0) _x = 0;
              if (_y < 0) _y = 0;
              if (_x > size.width - bubbleSize) _x = size.width - bubbleSize;
              if (_y > size.height - bubbleSize) _y = size.height - bubbleSize;
            });
          },
          // --- XỬ LÝ KHI BẤM VÀO BONG BÓNG ---
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIChatScreen()),
            );
          },
          // --- GIAO DIỆN BONG BÓNG ---
          child: AnimatedScale(
            scale: _isHover ? 1.08 : 1.0, // Phóng to nhẹ khi rê chuột
            duration: const Duration(milliseconds: 200),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Hình tròn chứa Robot
                Container(
                  width: bubbleSize,
                  height: bubbleSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    // Viền phát sáng
                    border: Border.all(color: Colors.teal.shade300, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(
                      'https://cdn-icons-png.flaticon.com/512/4712/4712010.png', // Icon Robot cũ
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // Chấm xanh thể hiện trạng thái "Online"
                Positioned(
                  bottom: 2,
                  right: 8,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),

                // Text nhãn "Bác sĩ AI" nổi lên khi Hover chuột
                if (_isHover)
                  Positioned(
                    top: -30,
                    left: -15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Bác sĩ AI",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
