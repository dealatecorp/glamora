import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_application/features/auth/models/auth_role.dart';
import 'package:saloon_application/features/auth/models/auth_session.dart';
import 'package:saloon_application/navigation/app_shell.dart';

void main() {
  testWidgets('saloon app renders navigation shell', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(
          session: AuthSession(
            id: 'test',
            displayName: 'Test Admin',
            role: AuthRole.admin,
            createdAt: DateTime(2024),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Glamora'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
