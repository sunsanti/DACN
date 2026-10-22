import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/doctor_provider.dart';
import 'providers/admin_provider.dart';
import 'screens/login_screen.dart';
import 'screens/patient_home_screen.dart';
import 'screens/doctor_home_screen.dart';
import 'screens/admin_home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
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
      theme: _theme,
      locale: const Locale('vi'),
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // Web/tablet: keep the phone-width layout centered instead of stretching.
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFE8EEF3),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: child,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

final _scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0E7C86));
final _radius = BorderRadius.circular(14);

final _theme = ThemeData(
  useMaterial3: true,
  colorScheme: _scheme,
  scaffoldBackgroundColor: const Color(0xFFF4F7F9),
  appBarTheme: AppBarTheme(
    backgroundColor: _scheme.primary,
    foregroundColor: _scheme.onPrimary,
    centerTitle: false,
    titleTextStyle: TextStyle(color: _scheme.onPrimary, fontSize: 19, fontWeight: FontWeight.w600),
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: _scheme.onPrimary,
    unselectedLabelColor: _scheme.onPrimary.withValues(alpha: 0.7),
    indicatorColor: _scheme.onPrimary,
    dividerColor: Colors.transparent,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: _radius,
      side: BorderSide(color: _scheme.outlineVariant.withValues(alpha: 0.6)),
    ),
    clipBehavior: Clip.antiAlias,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: _radius),
    enabledBorder: OutlineInputBorder(
      borderRadius: _radius,
      borderSide: BorderSide(color: _scheme.outlineVariant),
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      shape: RoundedRectangleBorder(borderRadius: _radius),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: _radius)),
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: _scheme.primary,
    foregroundColor: _scheme.onPrimary,
  ),
);

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
    if (auth.role == 'doctor') {
      return const DoctorHomeScreen();
    }
    if (auth.role == 'admin') {
      return const AdminHomeScreen();
    }
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
