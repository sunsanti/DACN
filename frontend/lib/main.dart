import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/appointment_provider.dart';
import 'screens/login_screen.dart';
import 'screens/patient_home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
      ],
      child: const DacnApp(),
    ),
  );
}

class DacnApp extends StatelessWidget {
  const DacnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DACN - Đặt lịch khám',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Routes by auth state + role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }
    if (auth.role == 'patient') {
      return const PatientHomeScreen();
    }
    // Doctor/Admin UIs are a later slice.
    return _RolePlaceholder(role: auth.role ?? '');
  }
}

class _RolePlaceholder extends StatelessWidget {
  final String role;
  const _RolePlaceholder({required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vai trò: $role')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Giao diện cho vai "$role" sẽ được làm ở giai đoạn sau.\n'
              'Hiện chỉ có luồng Bệnh nhân.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<AuthProvider>().logout(),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    );
  }
}
