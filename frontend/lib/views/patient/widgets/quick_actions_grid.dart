import 'package:flutter/material.dart';

// --- IMPORT CÁC MÀN HÌNH CHỨC NĂNG ---
import '../ai_chat_screen.dart';
import '../medical_history_screen.dart';
import '../profile_screen.dart';
// 🌟 ĐÃ SỬA: Import file đặt lịch khám mới của Quý (đảm bảo tên file này là appointment_screen.dart)
import '../appointment_screen.dart'; 

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {
        'label': 'Trợ lý AI',
        'color': Colors.purple,
        'image': 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?q=80&w=600&auto=format&fit=crop',
      },
      {
        'label': 'Đặt lịch khám',
        'color': Colors.blue,
        'image': 'https://images.unsplash.com/photo-1532938911079-1b06ac7ceec7?w=600&auto=format&fit=crop&q=60',
      },
      {
        'label': 'Hồ sơ bệnh án',
        'color': Colors.teal,
        'image': 'https://images.unsplash.com/photo-1586281380349-632531db7ed4?q=80&w=600&auto=format&fit=crop',
      },
      {
        'label': 'Hồ sơ cá nhân',
        'color': Colors.indigo,
        'image': 'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?q=80&w=600&auto=format&fit=crop',
      },
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.95,
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
          } 
          // 🌟 ĐÃ SỬA: Chuyển hướng đến AppointmentScreen khi bấm vào "Đặt lịch khám"
          else if (widget.data['label'] == 'Đặt lịch khám') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AppointmentScreen()), 
            );
          } 
          else if (widget.data['label'] == 'Hồ sơ bệnh án') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MedicalHistoryScreen()),
            );
          } 
          else if (widget.data['label'] == 'Hồ sơ cá nhân') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _isHover ? -8 : 0, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isHover ? brandColor.withOpacity(0.3) : Colors.black.withOpacity(0.08),
                blurRadius: _isHover ? 20 : 10,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: _isHover ? brandColor.withOpacity(0.5) : Colors.transparent,
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedScale(
                        scale: _isHover ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        child: Image.network(
                          widget.data['image'],
                          fit: BoxFit.cover,
                        ),
                      ),
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
                              colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Color(0xFFEAF2FF)],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.data['label'],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isHover ? brandColor : const Color(0xFF1E2638),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(top: 6),
                        height: 3,
                        width: _isHover ? 40 : 0,
                        decoration: BoxDecoration(
                          color: brandColor,
                          borderRadius: BorderRadius.circular(2),
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