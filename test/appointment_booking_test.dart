import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/features/appointments/screens/appointment_booking_screen.dart';
import 'package:saloon_application/core/widgets/primary_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every catalog service has an eligible active employee', () async {
    final repository = DemoRepository();
    final services = await repository.getServices();
    final employees = await repository.getEmployees();
    final missing = services
        .where(
          (service) => !employees.any(
            (employee) =>
                employee.serviceIds.contains(service.id) &&
                service.assignedEmployeeIds.contains(employee.id),
          ),
        )
        .map((service) => service.id)
        .toList();

    expect(missing, isEmpty);
  });

  testWidgets('service selection opens eligible employee selection', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(800, 1200)
      ..devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(home: AppointmentBookingScreen(repository: DemoRepository())),
    );
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pump();
    await tester.tap(find.text('Riya Shetty').last);
    await tester.pump();
    await tester.tap(find.byType(PrimaryButton).first);
    await tester.pump();

    expect(find.text('Signature Cut & Finish'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Signature Cut & Finish'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    final serviceTile = find.ancestor(
      of: find.text('Signature Cut & Finish'),
      matching: find.byType(ListTile),
    );
    tester.widget<ListTile>(serviceTile).onTap?.call();
    await tester.pump();
    await tester.pump();

    expect(find.text('Employee for Signature Cut & Finish'), findsOneWidget);
  });
}
