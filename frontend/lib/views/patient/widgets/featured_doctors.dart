import 'package:flutter/material.dart';
import '../doctor_detail_screen.dart';

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Colors.blue.shade700, // Đổi sang xanh nước biển
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
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisSpacing: 24,
                crossAxisSpacing: 24,
                childAspectRatio: 0.65,
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
          transform: Matrix4.translationValues(0, _isHover ? -10 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHover
                  ? Colors.blue.shade300
                  : Colors.transparent, // Đổi sang xanh nước biển
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHover
                    ? Colors.blue.withOpacity(0.15) // Đổi sang xanh nước biển
                    : Colors.black.withOpacity(0.04),
                blurRadius: _isHover ? 24 : 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          // Bọc toàn bộ Column bằng ClipRRect để đảm bảo nền gradient bên dưới
          // và ảnh bên trên đều không bị tràn ra khỏi viền bo tròn 24px của Card.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. PHẦN ẢNH CHÂN DUNG
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedScale(
                        scale: _isHover ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        child: Image.network(
                          widget.doctor['image'],
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
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

                // 2. PHẦN THÔNG TIN BÁC SĨ CÓ NỀN GRADIENT NHẠT
                Container(
                  // Áp dụng Gradient mượt mà từ Trắng -> Xanh dương nhạt mờ ảo
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white,
                        Color(
                          0xFFEAF2FF,
                        ), // Đổi sang mã màu Xanh nước biển nhạt
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.doctor['name'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _isHover
                              ? Colors
                                    .blue
                                    .shade700 // Đổi sang xanh nước biển
                              : const Color(0xFF1A1C1E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.doctor['specialty'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _isHover
                              ? Colors.blue
                              : Colors.blue.shade50, // Đổi sang xanh nước biển
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
                                : Colors
                                      .blue
                                      .shade700, // Đổi sang xanh nước biển
                          ),
                        ),
                      ),
                    ],
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
