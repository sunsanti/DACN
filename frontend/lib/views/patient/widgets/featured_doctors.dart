import 'package:flutter/material.dart';
import '../doctor_detail_screen.dart';
// (Sau này Quý import trang DoctorDetailScreen của Quý vào đây)
// import '../doctor_detail_screen.dart';

class FeaturedDoctors extends StatelessWidget {
  const FeaturedDoctors({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu mẫu với ảnh chân dung bác sĩ chất lượng cao
    final List<Map<String, dynamic>> doctors = [
      {
        'name': 'PGS.TS Trần Thị Ngọc',
        'specialty': 'Nội Tiết - Đái Tháo Đường',
        'rating': 4.9,
        'reviews': 128,
        'image':
            'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=500&q=80',
      },
      {
        'name': 'BSCKII Lê Văn Minh',
        'specialty': 'Cơ Xương Khớp',
        'rating': 4.8,
        'reviews': 95,
        'image':
            'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=500&q=80',
      },
      {
        'name': 'ThS.BS Hà Văn Quyết',
        'specialty': 'Tiêu Hóa - Gan Mật',
        'rating': 4.7,
        'reviews': 210,
        'image':
            'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=500&q=80',
      },
      {
        'name': 'BS. Nguyễn Phương',
        'specialty': 'Nhi Khoa',
        'rating': 5.0,
        'reviews': 342,
        'image':
            'https://images.unsplash.com/photo-1594824416928-1b641697200e?w=500&q=80',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // --- HEADER CỦA SECTION ---
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Bác sĩ nổi bật",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1C1E),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Chuyên gia hàng đầu sẵn sàng tư vấn",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Xem tất cả",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // --- LƯỚI DANH SÁCH BÁC SĨ (RESPONSIVE CHO CẢ PC & MOBILE) ---
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              // Đảm bảo thẻ luôn giãn đều, trên PC có thể hiển thị 4 cột, Mobile là 2 cột
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280, // Chiều rộng lý tưởng cho 1 thẻ bác sĩ
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio:
                    0.75, // Tỷ lệ thẻ hình chữ nhật đứng (rộng / cao)
              ),
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                return _DoctorCard(doctor: doctors[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

// --- WIDGET THẺ BÁC SĨ TÍCH HỢP HIỆU ỨNG HOVER ---
class _DoctorCard extends StatefulWidget {
  final Map<String, dynamic> doctor;
  const _DoctorCard({required this.doctor});

  @override
  State<_DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<_DoctorCard> {
  bool _isHover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHover = true),
      onExit: (_) => setState(() => _isHover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DoctorDetailScreen()),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          // Hover: Thẻ sẽ nổi hẳn lên trên
          transform: Matrix4.translationValues(0, _isHover ? -10 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHover ? Colors.teal.shade300 : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHover
                    ? Colors.teal.withOpacity(0.15)
                    : Colors.black.withOpacity(0.04),
                blurRadius: _isHover ? 24 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. PHẦN ẢNH CHÂN DUNG (Nửa trên của thẻ)
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Zoom nhẹ ảnh khi Hover để tạo chiều sâu
                      AnimatedScale(
                        scale: _isHover ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        child: Image.network(
                          widget.doctor['image'],
                          fit: BoxFit.cover,
                          alignment:
                              Alignment.topCenter, // Ưu tiên hiển thị khuôn mặt
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  Icons.person,
                                  color: Colors.grey,
                                  size: 50,
                                ),
                              ),
                        ),
                      ),
                      // Điểm nhấn sao Đánh giá (Rating Badge) nổi trên ảnh
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.doctor['rating'].toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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

              // 2. PHẦN THÔNG TIN BÁC SĨ (Nửa dưới của thẻ)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.doctor['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isHover
                                  ? Colors.teal.shade700
                                  : const Color(0xFF1A1C1E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.doctor['specialty'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // Nút "Đặt khám ngay" giả lập hiện ra sắc nét khi Hover
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isHover ? Colors.teal : Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "Đặt khám ngay",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _isHover
                                ? Colors.white
                                : Colors.teal.shade700,
                          ),
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
    );
  }
}
