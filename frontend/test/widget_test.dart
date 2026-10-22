import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/ui.dart';
import 'package:frontend/main.dart';
import 'package:frontend/providers/admin_provider.dart';
import 'package:frontend/providers/appointment_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/doctor_provider.dart';

void main() {
  testWidgets('Logged-out app shows login and validates empty form', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const DacnApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('DACN Clinic'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();
    expect(find.text('Email không hợp lệ'), findsOneWidget);
    expect(find.text('Nhập mật khẩu'), findsOneWidget);
  });

  test('format helpers', () {
    final d = DateTime(2026, 3, 7, 9, 5);
    expect(fmtDateTime(d), '07/03/2026 09:05');
    expect(fmtHours(8.0), '8h');
    expect(fmtHours(10.25), '10.25h');
  });
}
