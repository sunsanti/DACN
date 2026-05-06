import 'package:flutter/material.dart';
import '../ai_chat_screen.dart';
import '../booking_screen.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    // Danh sách chức năng với Ảnh thật (Chất lượng cao) phù hợp với từng nội dung
    final List<Map<String, dynamic>> actions = [
      {
        'label': 'Đặt lịch khám',
        'color': Colors.blue,
        // Ảnh bác sĩ đang cầm bệnh án/ipad (link mới siêu ổn định)
        'image':
            'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?w=600&auto=format&fit=crop&q=60',
      },
      {
        'label': 'Trợ lý AI',
        'color': Colors.purple,
        'image':
            'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?q=80&w=600&auto=format&fit=crop',
      },
      {
        'label': 'Bảng giá dịch vụ',
        'color': Colors.orange,
        'image':
            'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?q=80&w=600&auto=format&fit=crop',
      },
      {
        'label': 'Tin tức y tế',
        'color': Colors.green,
        // Ảnh không gian y tế / bài báo (link mới siêu ổn định)
        'image':
            'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=600&auto=format&fit=crop&q=60',
      },
      {
        'label': 'Hệ thống phòng khám',
        'color': Colors.redAccent,
        'image':
            'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?q=80&w=600&auto=format&fit=crop',
      },
      {
        'label': 'Hồ sơ bệnh án',
        'color': Colors.teal,
        'image':
            'https://images.unsplash.com/photo-1586281380349-632531db7ed4?q=80&w=600&auto=format&fit=crop',
      },
      {
        'label': 'Hỏi đáp bác sĩ',
        'color': Colors.indigo,
        'image':
            'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?q=80&w=600&auto=format&fit=crop',
      },
      {
        'label': 'Tiện ích khác',
        'color': Colors.blueGrey,
        'image':
            'https://images.unsplash.com/photo-1550831107-1553da8c8464?q=80&w=600&auto=format&fit=crop',
      },
    ];

    return Center(
      child: ConstrainedBox(
        // Giới hạn chiều rộng tối đa trên màn hình PC siêu to để app không bị bè ngang quá mức
        constraints: const BoxConstraints(maxWidth: 1200),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          // --- BÍ QUYẾT RESPONSIVE LẤP ĐẦY KHOẢNG TRẮNG Ở ĐÂY ---
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent:
                260, // Chiều rộng tối đa của 1 thẻ. Tự động chia số cột dựa vào màn hình.
            mainAxisSpacing: 20, // Khoảng cách dọc
            crossAxisSpacing: 20, // Khoảng cách ngang
            childAspectRatio: 1.1, // Tỷ lệ thẻ (chiều rộng / chiều cao)
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _ActionImageCard(data: actions[index]);
          },
        ),
      ),
    );
  }
}

// --- THIẾT KẾ THẺ CHỨA ẢNH SIÊU ĐẸP & HIỆU ỨNG HOVER ---
class _ActionImageCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _ActionImageCard({required this.data});

  @override
  State<_ActionImageCard> createState() => _ActionImageCardState();
}

class _ActionImageCardState extends State<_ActionImageCard> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    final Color brandColor = widget.data['color'];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (widget.data['label'] == 'Trợ lý AI') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIChatScreen()),
            );
          } else if (widget.data['label'] == 'Đặt lịch khám') {
            // Nhấn từ ngoài trang chủ thì KHÔNG truyền tên bác sĩ
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BookingScreen()),
            );
          } else {
            // ... Code hiện SnackBar giữ nguyên
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          // Hover: Đẩy thẻ nhô lên một chút (translation)
          transform: Matrix4.translationValues(0, _isHover ? -8 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isHover
                    ? brandColor.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: _isHover ? 20 : 10,
                offset: const Offset(0, 8),
              ),
            ],
            // Bo viền phát sáng nhẹ khi hover
            border: Border.all(
              color: _isHover
                  ? brandColor.withOpacity(0.5)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          // ClipRRect giúp ảnh bo góc theo viền của Container
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. PHẦN ẢNH NỀN Ở TRÊN CÙNG
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ảnh chính
                      AnimatedScale(
                        scale: _isHover ? 1.1 : 1.0, // Zoom nhẹ ảnh khi Hover
                        duration: const Duration(milliseconds: 400),
                        child: Image.network(
                          widget.data['image'],
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Lớp phủ Gradient đen mờ dưới cùng của ảnh để phân tách với phần chữ trắng
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 2. PHẦN TIÊU ĐỀ NẰM DƯỚI KHUNG TRẮNG
                Expanded(
                  flex: 2,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.data['label'],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            // Chữ đổi màu theo chủ đề khi Hover
                            color: _isHover
                                ? brandColor
                                : const Color(0xFF2D3233),
                          ),
                        ),
                        // Thanh kẻ ngang trang trí mượt mà
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(top: 8),
                          height: 3,
                          width: _isHover ? 40 : 0, // Dài ra khi hover
                          decoration: BoxDecoration(
                            color: brandColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
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
