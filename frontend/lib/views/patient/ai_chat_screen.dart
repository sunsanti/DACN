import 'package:flutter/material.dart';
import 'appointment_screen.dart'; // 🌟 Import màn hình đặt lịch của Quý để chuyển data

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  
  // 🌟 THAM SỐ MỚI: Dùng để lưu kết quả cấu trúc sẽ đẩy qua file PDF của Bác sĩ
  String? _finalAiDiagnosis; 

  // Danh sách tin nhắn mẫu
  final List<Map<String, dynamic>> _messages = [
    {
      "isMe": false,
      "text": "Xin chào Quý! Tôi là Trợ lý Y tế AI. Quý đang gặp vấn đề gì về sức khỏe cần tôi tư vấn hôm nay?",
      "time": "10:00 AM",
    },
  ];

  // Hàm xử lý khi gửi tin nhắn (Đã tích hợp luồng xử lý AI của Quý)
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userText = _messageController.text;

    setState(() {
      _messages.add({"isMe": true, "text": userText, "time": "Vừa xong"});
      _messageController.clear();
      _isTyping = true; 
    });

    _scrollToBottom();

    // Giả lập độ trễ AI xử lý Tiền xử lý -> Model 1 -> Model 2 -> Kiểm tra dấu hiệu nguy hiểm (2 giây)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;

        // 🌟 1. ĐÂY LÀ CHUỖI KẾT QUẢ SẼ ĐƯỢC KHÓA LẠI ĐỂ IN VÀO PDF GỬI BÁC SĨ:
        _finalAiDiagnosis = 
            "• Chuyên khoa gợi ý: Da liễu\n"
            "• Dự đoán bệnh lý: Viêm da tiếp xúc dị ứng / Mề đay cấp tính\n"
            "• Dấu hiệu nguy hiểm: KHÔNG PHÁT HIỆN (Không có sốc phản vệ, không khó thở)\n"
            "• Ghi chú hệ thống: Đã khóa dữ liệu khai báo tự động từ Chatbot AI.";

        // 🌟 2. AI TRẢ LỜI TỰ NHIÊN TRÊN BONG BÓNG CHAT:
        _messages.add({
          "isMe": false,
          "text": "Tôi đã phân tích xong triệu chứng của Quý bằng mô hình học máy. Dưới đây là kết quả sơ bộ:\n\n"
                  "🏥 Chuyên khoa đề xuất: DA LIỄU\n"
                  "🧬 Bệnh lý có thể liên quan: Viêm da dị ứng hoặc tổn thương biểu bì nông.\n"
                  "⚠️ Cảnh báo nguy hiểm: An toàn (Không có dấu hiệu cấp cứu).\n\n"
                  "Hệ thống đã tự động khóa kết quả này để chuyển thẳng vào Phiếu chẩn đoán của Bác sĩ. Quý vui lòng bấm nút phía dưới để chuyển sang màn hình chọn giờ khám nhé!",
          "time": "Vừa xong",
        });
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF), 
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade50, 
                  backgroundImage: const NetworkImage(
                    'https://cdn-icons-png.flaticon.com/512/4712/4712010.png',
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade400, 
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bác sĩ AI",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Luôn sẵn sàng hỗ trợ",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ), 
                ),
              ],
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800), 
          child: Column(
            children: [
              // 1. KHU VỰC HIỂN THỊ TIN NHẮN
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildChatBubble(
                      msg['text'],
                      msg['isMe'],
                      msg['time'],
                    );
                  },
                ),
              ),

              // 2. HIỆU ỨNG "AI ĐANG GÕ..."
              if (_isTyping)
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Bác sĩ AI đang nhập tin nhắn...",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),

              // 🌟 3. NÚT ĐẨY DỮ LIỆU SANG LỊCH KHÁM (Chỉ xuất hiện khi đã có kết quả _finalAiDiagnosis)
              if (_finalAiDiagnosis != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month, color: Colors.white),
                      label: const Text(
                        "ĐẶT LỊCH VỚI KẾT QUẢ AI", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600, // Màu xanh lá tạo độ tin cậy, nổi bật
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        // Điều hướng sang AppointmentScreen và truyền cứng chuỗi kết quả AI qua constructor
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppointmentScreen(
                              patientId: 1, // Thay bằng ID thực tế của Quý nếu có
                              aiDiagnosisResult: _finalAiDiagnosis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // 4. THANH NHẬP LIỆU (Input Field)
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  // Giao diện bong bóng tin nhắn (Giữ nguyên toàn bộ tham số cũ của Quý)
  Widget _buildChatBubble(String text, bool isMe, String time) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7, 
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.white, 
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                color: isMe ? Colors.blue.shade100 : Colors.grey.shade500, 
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Giao diện thanh nhập liệu (Giữ nguyên toàn bộ cấu trúc cũ của Quý)
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.attach_file, color: Colors.grey.shade600),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: "Mô tả triệu chứng của bạn...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.blue, 
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}