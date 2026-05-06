import 'dart:async';
import 'package:flutter/material.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  // PageController giúp điều khiển thao tác vuốt trang
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // Danh sách dữ liệu Banner (Sau này Quý có thể gọi từ Backend trả về)
  final List<Map<String, String>> _banners = [
    {
      "image":
          "https://images.unsplash.com/photo-1638202993928-7267aad84c31?q=80&w=800&auto=format&fit=crop",
      "title": "Tầm soát ung thư",
      "subtitle": "Giảm 20% gói khám tổng quát tháng này",
    },
    {
      "image":
          "https://images.unsplash.com/photo-1579684385127-1ef15d508118?q=80&w=800&auto=format&fit=crop",
      "title": "Chuyên gia Tim mạch",
      "subtitle": "Đặt lịch tư vấn với PGS.TS Nguyễn Văn A",
    },
    {
      "image":
          "https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?q=80&w=800&auto=format&fit=crop",
      "title": "Tư vấn từ xa 24/7",
      "subtitle": "Kết nối Video Call ngay với bác sĩ trực tuyến",
    },
  ];

  @override
  void initState() {
    super.initState();
    // Cài đặt Timer tự động chuyển trang mỗi 4 giây
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      // Kiểm tra xem widget còn tồn tại không trước khi hiệu ứng chạy
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600), // Thời gian vuốt rất êm
          curve: Curves.fastOutSlowIn, // Hiệu ứng nhanh ở đầu, chậm dần ở cuối
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Phải hủy Timer khi tắt app để tránh rò rỉ bộ nhớ
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Khung ảnh Slider
        SizedBox(
          height: 160, // Chiều cao lý tưởng cho Banner
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return _buildBannerItem(_banners[index]);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Các chấm tròn Indicator ở dưới
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => _buildDotIndicator(index == _currentPage),
          ),
        ),
      ],
    );
  }

  // --- HÀM VẼ TỪNG BANNER ---
  Widget _buildBannerItem(Map<String, String> banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(banner["image"]!),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        // Lớp phủ Gradient đen mờ giúp chữ trắng nổi bật lên (Kỹ thuật Dark Overlay)
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              banner["title"]!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              banner["subtitle"]!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HÀM VẼ CHẤM TRÒN ---
  Widget _buildDotIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      // Nút đang chọn thì dài ra thành viên thuốc, nút không chọn thì tròn
      width: isActive ? 20 : 6,
      decoration: BoxDecoration(
        color: isActive ? Colors.teal : Colors.teal.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
