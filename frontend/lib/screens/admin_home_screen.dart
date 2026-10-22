import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ui.dart';
import '../models/doctor_salary.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import 'add_doctor_screen.dart';
import 'admin_disease_screen.dart';
import 'admin_news_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_payments_screen.dart';
import '../services/payment_service.dart';
import 'admin_doctor_detail_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _payments = PaymentService();
  int _unread = 0;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().load();
    });
    _refreshUnread();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _refreshUnread());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  /// Bell badge: new "money received" / "check this transfer" notifications.
  Future<void> _refreshUnread() async {
    try {
      final n = await _payments.unreadCount();
      if (mounted) setState(() => _unread = n);
    } catch (_) {
      // badge is best-effort
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    _refreshUnread();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const SessionTitle('Quản lý bác sĩ & lương'),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            icon: Badge(
              isLabelVisible: _unread > 0,
              label: Text('$_unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () => _open(const AdminNotificationsScreen()),
          ),
          PopupMenuButton<Widget>(
            tooltip: 'Menu',
            onSelected: _open,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: AdminPaymentsScreen(),
                child: ListTile(leading: Icon(Icons.point_of_sale), title: Text('Thanh toán')),
              ),
              const PopupMenuItem(
                value: AdminDiseaseScreen(),
                child: ListTile(leading: Icon(Icons.price_change_outlined), title: Text('Bảng giá bệnh')),
              ),
              const PopupMenuItem(
                value: AdminNewsScreen(),
                child: ListTile(leading: Icon(Icons.newspaper), title: Text('Tin tức')),
              ),
              PopupMenuItem(
                // value null = "canceled" in Flutter, so onSelected never fires; use onTap.
                onTap: () => context.read<AuthProvider>().logout(),
                child: const ListTile(leading: Icon(Icons.logout), title: Text('Đăng xuất')),
              ),
            ],
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
      return EmptyState(Icons.cloud_off, 'Lỗi: ${provider.error}');
    }
    if (provider.salaries.isEmpty) {
      return const EmptyState(Icons.group_off_outlined, 'Chưa có bác sĩ.\nNhấn "Thêm bác sĩ".');
    }
    final total = provider.salaries.fold<int>(0, (sum, s) => sum + s.salary);
    final hours = provider.salaries.fold<num>(0, (sum, s) => sum + s.totalHours);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        _summary(total, hours, provider.salaries.length),
        const SizedBox(height: 16),
        for (final s in provider.salaries) ...[_tile(s), const SizedBox(height: 12)],
      ],
    );
  }

  Widget _summary(int total, num hours, int doctors) {
    final scheme = Theme.of(context).colorScheme;
    final on = scheme.onPrimary;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primary, scheme.primary.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tổng lương phải trả', style: TextStyle(color: on.withValues(alpha: 0.85))),
          const SizedBox(height: 4),
          Text(fmtMoney(total), style: TextStyle(color: on, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('$doctors bác sĩ  ·  ${fmtHours(hours)} làm việc', style: TextStyle(color: on.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _tile(DoctorSalary s) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: UserAvatar(avatarUrl: s.avatar, name: s.name.trim().split(' ').last),
        title: Text('BS. ${s.name}', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${fmtHours(s.totalHours)}  ·  ${fmtMoney(s.hourlyRate)}/giờ'),
        trailing: Text(fmtMoney(s.salary),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Colors.green.shade700)),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AdminDoctorDetailScreen(doctorId: s.doctorId)),
        ),
      ),
    );
  }
}
