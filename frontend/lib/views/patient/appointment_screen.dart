import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🌟 THÊM: Đọc ID người dùng đang nhập
import '../../services/api_service.dart'; 
import '../../models/appointment_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentScreen extends StatefulWidget {
  final int? patientId; // Sửa thành nullable để ưu tiên check SharedPreferences
  final String? aiDiagnosisResult; 

  const AppointmentScreen({super.key, this.patientId, this.aiDiagnosisResult});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Các Controller cho Form
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(text: "Bệnh viện Đa Khoa - Phòng khám Khu A");

  // Biến lưu thông tin chọn từ UI
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1)); 
  String? _selectedTimeSlot; 
  dynamic _selectedDoctor; 

  // Danh sách dữ liệu tương tác với API Backend
  List<dynamic> _appointments = [];
  List<String> _timeSlots = []; 
  List<dynamic> _availableDoctors = []; 

  // Trạng thái Loading và ID thực tế
  int _resolvedPatientId = 1; // ID mặc định dự phòng
  bool _isInitLoading = true; // Loading lúc check ID khi vừa vào trang
  bool _isLoadingList = false;
  bool _isLoadingSlots = false;
  bool _isLoadingDoctors = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    if (widget.aiDiagnosisResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.animateTo(1); 
      });
    }

    _initPatientAndLoadData(); // 🌟 Chạy hàm khởi tạo ID động
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // 🌟 HÀM KHỞI TẠO: Lấy ID người dùng thực tế từ bộ nhớ máy
  Future<void> _initPatientAndLoadData() async {
    try {
      if (widget.patientId != null) {
        _resolvedPatientId = widget.patientId!;
      } else {
        final prefs = await SharedPreferences.getInstance();
        _resolvedPatientId = prefs.getInt('patientId') ?? 1; // Lấy ID thật, không có thì fallback về 1
      }
    } catch (e) {
      debugPrint("Lỗi đọc SharedPreferences tại AppointmentScreen: $e");
    } finally {
      if (mounted) {
        setState(() => _isInitLoading = false);
      }
      // Sau khi đã chốt được ID chuẩn, tiến hành gọi các API liên quan
      _loadAppointments(); 
      _loadTimeSlots(); 
    }
  }

  // 1. Tải danh sách lịch hẹn hiện tại (Đã đổi sang dùng ID động 🚀)
  Future<void> _loadAppointments() async {
    if (!mounted) return;
    setState(() => _isLoadingList = true);
    try {
      var data = await ApiService.getAppointments(_resolvedPatientId);
      if (mounted) {
        setState(() => _appointments = data);
      }
    } catch (e) {
      debugPrint("Lỗi load danh sách lịch hẹn: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingList = false);
      }
    }
  }

  // 2. Lấy danh sách các slot giờ cố định
  Future<void> _loadTimeSlots() async {
    if (!mounted) return;
    setState(() => _isLoadingSlots = true);
    try {
      List<String> slots = await ApiService.getTimeSlots(); 
      if (mounted) {
        setState(() {
          _timeSlots = slots;
          if (_timeSlots.isNotEmpty) _selectedTimeSlot = _timeSlots[0]; 
        });
      }
      _fetchAvailableDoctors();
    } catch (e) {
      debugPrint("Lỗi lấy khung giờ khám: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  // 3. Lọc bác sĩ rảnh theo ngày và giờ đã chọn
  Future<void> _fetchAvailableDoctors() async {
    if (_selectedTimeSlot == null || !mounted) return;
    
    setState(() {
      _isLoadingDoctors = true;
      _availableDoctors = [];
      _selectedDoctor = null; 
    });

    try {
      String formattedDate = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
      String dateTimeParam = "$formattedDate $_selectedTimeSlot:00";

      List<dynamic> doctors = await ApiService.getAvailableDoctors(dateTimeParam);
      
      if (mounted) {
        setState(() {
          _availableDoctors = doctors;
          if (_availableDoctors.isNotEmpty) _selectedDoctor = _availableDoctors[0]; 
        });
      }
    } catch (e) {
      debugPrint("Lỗi lọc bác sĩ rảnh: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoadingDoctors = false);
      }
    }
  }

  // Hàm Picker chọn ngày
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _fetchAvailableDoctors(); 
    }
  }

  // 4. Hàm bấm đặt lịch - Gửi dữ liệu đồng bộ cấu trúc Database Postgres (Đã gán ID động 🚀)
  Future<void> _submitAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTimeSlot == null || _selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Vui lòng chọn đầy đủ thời gian và bác sĩ!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    List<String> timeParts = _selectedTimeSlot!.split(':');
    DateTime fullDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    String finalNote = _noteController.text.trim();
    if (widget.aiDiagnosisResult != null) {
      finalNote = "👤 Bệnh nhân mô tả: ${finalNote.isEmpty ? 'Không có ghi chú thêm' : finalNote}\n\n🤖 AI Chẩn đoán:\n${widget.aiDiagnosisResult}";
    }

    Map<String, dynamic> appointmentData = {
      'apTime': fullDateTime.toIso8601String(),
      'confirmDate': null,
      'address': _addressController.text.trim(),
      'note': finalNote.isEmpty ? null : finalNote, 
      'confirmCondition': 0, // 0 = Chờ xác nhận
      'doctorName': _selectedDoctor['name'] ?? 'Bác sĩ phòng khám', 
      'doctorId': _selectedDoctor['id'], 
      'patientId': _resolvedPatientId, // Gửi ID chuẩn của người dùng đang đăng nhập lên Postgres
      'aiDiagnosticPdf': null,
    };

    bool success = await ApiService.createAppointment(appointmentData);

    if (mounted) {
      setState(() => _isSubmitting = false);
    }

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Lịch hẹn đã tạo thành công & AI đã phân tích biểu mẫu!'), backgroundColor: Colors.green),
        );
        _noteController.clear();
        _loadAppointments(); 
        _tabController.animateTo(0); 
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Đặt lịch thất bại. Ca khám này vừa có người đặt trước!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F9FF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      appBar: AppBar(
        title: const Text('Hệ Thống Đặt Lịch Thông Minh AI', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: "Lịch của tôi"),
            Tab(icon: Icon(Icons.add_task), text: "Đặt lịch mới"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentListTab(),
          _buildBookingFormTab(),
        ],
      ),
    );
  }

  // ---------------- TAB 1: DANH SÁCH LỊCH HẸN ----------------
  Widget _buildAppointmentListTab() {
    if (_isLoadingList) return const Center(child: CircularProgressIndicator());
    if (_appointments.isEmpty) {
      return const Center(child: Text("Bạn chưa có lịch hẹn nào.", style: TextStyle(color: Colors.grey)));
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final item = _appointments[index];
          
          Color statusColor = Colors.orange;
          String statusText = "Chờ duyệt";
          if (item.confirmCondition == 1) {
            statusColor = Colors.green;
            statusText = "Đã duyệt";
          } else if (item.confirmCondition == 2) {
            statusColor = Colors.red;
            statusText = "Đã hủy";
          }

          DateTime parsedTime = DateTime.tryParse(item.apTime?.toString() ?? '') ?? DateTime.now();
          String formattedTime = "${parsedTime.hour.toString().padLeft(2, '0')}:${parsedTime.minute.toString().padLeft(2, '0')} - ${parsedTime.day}/${parsedTime.month}/${parsedTime.year}";

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.doctorName ?? "Bác sĩ", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue),
                          overflow: TextOverflow.ellipsis, 
                        ),
                      ),
                      const SizedBox(width: 8), 
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15), // Dùng tương thích ngược mượt mà
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(formattedTime, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (item.note != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Text("Ghi chú: ${item.note}", style: const TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic)),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (item.aiDiagnosticPdf != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          String path = item.aiDiagnosticPdf!;
                          String baseUrl = "http://192.168.56.1:3000"; 
                          
                          if (!path.startsWith('/')) {
                            path = '/$path';
                          }
                          
                          String fullUrl = "$baseUrl$path";
                          final url = Uri.parse(fullUrl);
                          
                          try {
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication); 
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('❌ Không có app mở PDF!'), backgroundColor: Colors.red),
                                );
                              }
                            }
                          } catch (e) {
                            debugPrint("Lỗi khi mở PDF: $e");
                          }
                        },
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                        label: const Text("Phiếu chẩn đoán AI (.pdf)", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- TAB 2: FORM ĐẶT LỊCH HẸN MỚI ----------------
  Widget _buildBookingFormTab() {
    String dateStr = "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("1. Chọn Ngày khám", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: _inputDecoration(Icons.calendar_month),
                          child: Text(dateStr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text("2. Khung giờ khám (Mỗi ca 15 phút)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            _isLoadingSlots 
                ? const Center(child: LinearProgressIndicator())
                : DropdownButtonFormField<String>(
                    value: _selectedTimeSlot,
                    isExpanded: true, 
                    decoration: _inputDecoration(Icons.alarm),
                    items: _timeSlots.map((slot) => DropdownMenuItem(value: slot, child: Text("Ca khám: $slot"))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedTimeSlot = val);
                      _fetchAvailableDoctors(); 
                    },
                  ),
            const SizedBox(height: 16),

            const Text("3. Bác sĩ trực ca (Chỉ hiện bác sĩ đang rảnh)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            _isLoadingDoctors 
                ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Row(children: [CircularProgressIndicator(strokeWidth: 2), SizedBox(width: 12), Text("Đang rà soát lịch bác sĩ...")])))
                : _availableDoctors.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Ca này chưa có lịch bác sĩ trực. Hãy chọn giờ khác!", 
                                style: TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<dynamic>(
                        value: _selectedDoctor,
                        isExpanded: true, 
                        decoration: _inputDecoration(Icons.person_search),
                        items: _availableDoctors.map((doc) => DropdownMenuItem(
                          value: doc, 
                          child: Text(
                            "${doc['name']} - Chuyên khoa",
                            overflow: TextOverflow.ellipsis, 
                          ),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedDoctor = val),
                      ),
            const SizedBox(height: 16),

            const Text("Nơi khám", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _addressController,
              decoration: _inputDecoration(Icons.local_hospital),
              validator: (v) => v!.trim().isEmpty ? "Vui lòng nhập địa điểm khám" : null,
            ),
            const SizedBox(height: 16),

            const Text("Lý do khám / Triệu chứng (Bạn tự mô tả)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _noteController,
              maxLines: 3,
              decoration: _inputDecoration(Icons.edit_note).copyWith(
                hintText: "Nhập thêm triệu chứng hoặc lời nhắn cho Bác sĩ...",
              ),
            ),
            const SizedBox(height: 16),

            if (widget.aiDiagnosisResult != null) ...[
              const Text("Kết quả chẩn đoán sơ bộ từ AI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50, 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_outline, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          "Dữ liệu tự động từ AI (Không thể chỉnh sửa)",
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Divider(),
                    Text(
                      widget.aiDiagnosisResult!,
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting || _availableDoctors.isEmpty ? null : _submitAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('XÁC NHẬN ĐẶT LỊCH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.blue.shade400),
      fillColor: Colors.white,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blue, width: 2)),
    );
  }
}