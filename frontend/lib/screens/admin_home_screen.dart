import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/doctor_salary.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import 'add_doctor_screen.dart';
import 'admin_doctor_detail_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().load();
    });
  }

  String _money(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '$buf đ';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Bác sĩ & Lương'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Thêm bác sĩ'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().load(),
        child: _body(provider),
      ),
    );
  }

  Widget _body(AdminProvider provider) {
    if (provider.loading && provider.salaries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null && provider.salaries.isEmpty) {
      return ListView(children: [
        const SizedBox(height: 120),
        Center(child: Text('Lỗi: ${provider.error}', textAlign: TextAlign.center)),
      ]);
    }
    if (provider.salaries.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 120),
        Center(child: Text('Chưa có bác sĩ.\nNhấn "Thêm bác sĩ".', textAlign: TextAlign.center)),
      ]);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: provider.salaries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _tile(provider.salaries[i]),
    );
  }

  Widget _tile(DoctorSalary s) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Text(s.doctorId.toString())),
        title: Text('BS. ${s.name}'),
        subtitle: Text('Số giờ làm: ${s.totalHours}h  ·  ${_money(s.hourlyRate)}/giờ'),
        trailing: Text(_money(s.salary),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AdminDoctorDetailScreen(doctorId: s.doctorId)),
        ),
      ),
    );
  }
}
