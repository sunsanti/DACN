import 'package:flutter/material.dart';
import '../../../models/patient_model.dart'; 
import '../../../services/api_service.dart'; // Đã thêm import ApiService

class EditProfileScreen extends StatefulWidget {
  final Patient patient;

  const EditProfileScreen({super.key, required this.patient});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers cho các trường văn bản và số
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cccdController;
  late TextEditingController _bhytController;
  late TextEditingController _avatarController;
  
  // Controller cho trường đăng nhập (Khóa)
  late TextEditingController _emailController;

  // Biến lưu trữ ngày sinh và giới tính 
  late DateTime _selectedDate;
  late String _selectedGender;
  
  // Biến cờ hiệu đang xử lý (loading)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Đổ dữ liệu từ model vào form, ép kiểu an toàn
    _nameController = TextEditingController(text: widget.patient.name?.toString() ?? "");
    _ageController = TextEditingController(text: widget.patient.age?.toString() ?? "");
    _phoneController = TextEditingController(text: widget.patient.phone?.toString() ?? "");
    _addressController = TextEditingController(text: widget.patient.address?.toString() ?? "");
    _cccdController = TextEditingController(text: widget.patient.cccd?.toString() ?? "");
    _bhytController = TextEditingController(text: widget.patient.bhyt?.toString() ?? "");
    _avatarController = TextEditingController(text: widget.patient.avatar?.toString() ?? "");
    
    // Email hiển thị nhưng không cho sửa
    _emailController = TextEditingController(text: widget.patient.email?.toString() ?? "");
    
    // Ngày sinh và giới tính
    _selectedDate = widget.patient.birthDate ?? DateTime.now();
    _selectedGender = widget.patient.gender?.toString() ?? "Khác"; 
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cccdController.dispose();
    _bhytController.dispose();
    _avatarController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // Hàm chọn ngày sinh
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FF),
      appBar: AppBar(
        title: const Text(
          "Cập nhật hồ sơ",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. THÔNG TIN ĐỊNH DANH ---
              const Text("Thông tin định danh", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 12),
              _buildInputField(controller: _nameController, label: "Họ và tên", icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildInputField(controller: _cccdController, label: "Số CCCD", icon: Icons.badge_outlined, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildInputField(controller: _bhytController, label: "Mã BHYT", icon: Icons.health_and_safety_outlined),
              const SizedBox(height: 24),

              // --- 2. THÔNG TIN CÁ NHÂN ---
              const Text("Thông tin cá nhân", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: "Ngày sinh",
                          prefixIcon: const Icon(Icons.cake_outlined, color: Colors.blue),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                        child: Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: ["Nam", "Nữ", "Khác"].contains(_selectedGender) ? _selectedGender : "Khác",
                      decoration: InputDecoration(
                        labelText: "Giới tính",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(value: "Nam", child: Text("Nam")),
                        DropdownMenuItem(value: "Nữ", child: Text("Nữ")),
                        DropdownMenuItem(value: "Khác", child: Text("Khác")),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedGender = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildInputField(
                      controller: _ageController, 
                      label: "Tuổi", 
                      icon: Icons.hourglass_bottom, 
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _buildInputField(
                      controller: _phoneController, 
                      label: "Số điện thoại", 
                      icon: Icons.phone_android_outlined, 
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildInputField(controller: _addressController, label: "Địa chỉ", icon: Icons.location_on_outlined),
              const SizedBox(height: 16),
              _buildInputField(controller: _avatarController, label: "Link ảnh đại diện", icon: Icons.image_outlined),
              const SizedBox(height: 24),

              // --- 3. THÔNG TIN ĐĂNG NHẬP (KHÓA) ---
              const Text("Thông tin đăng nhập (Không thể sửa)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              const SizedBox(height: 12),
              _buildInputField(
                controller: _emailController, 
                label: "Email tài khoản", 
                icon: Icons.email_outlined, 
                enabled: false,
              ),
              const SizedBox(height: 32),

              // --- NÚT LƯU THAY ĐỔI ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isLoading = true;
                      });

                      // 1. Gom dữ liệu vào Map
                      Map<String, dynamic> updatedData = {
                        "name": _nameController.text.trim(),
                        "age": int.tryParse(_ageController.text) ?? widget.patient.age ?? 0,
                        "phone": _phoneController.text.trim(),
                        "address": _addressController.text.trim(),
                        "cccd": _cccdController.text.trim(),
                        "bhyt": _bhytController.text.trim(),
                        "avatar": _avatarController.text.trim(),
                        "gender": _selectedGender,
                        "birthDate": _selectedDate.toIso8601String(), // NestJS thường thích định dạng ISO này
                      };

                      // 2. GỌI API THỰC TẾ
                      bool success = await ApiService.updatePatientProfile(widget.patient.id, updatedData);

                      setState(() {
                        _isLoading = false;
                      });

                      // 3. Xử lý sau khi có phản hồi
                      if (context.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lưu thông tin thành công!'), backgroundColor: Colors.green),
                          );
                          // Trả về true để trang ProfileScreen biết mà reload lại data mới
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Có lỗi xảy ra khi cập nhật. Vui lòng thử lại!'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "LƯU THAY ĐỔI",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget hỗ trợ vẽ ô nhập liệu
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled, 
      style: TextStyle(color: enabled ? Colors.black87 : Colors.grey),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? Colors.blue : Colors.grey),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: enabled ? (value) {
        if (value == null || value.trim().isEmpty) {
          return "Vui lòng nhập thông tin";
        }
        return null;
      } : null,
    );
  }
}