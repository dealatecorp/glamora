import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/features/billing/domain/billing_calculator.dart';
import 'package:saloon_application/models/salon_models.dart';

void main() {
  test('calculates percentage and fixed discounts with balance', () {
    final percentage = BillingCalculator.calculate(
      originalAmount: 2000,
      discountType: DiscountType.percentage,
      discountValue: 10,
    );
    final fixed = BillingCalculator.calculate(
      originalAmount: 2000,
      discountType: DiscountType.fixed,
      discountValue: 300,
    );

    expect(percentage.discountAmount, 200);
    expect(percentage.finalAmount, 1800);
    expect(percentage.balance, 1800);
    expect(fixed.discountAmount, 300);
    expect(fixed.finalAmount, 1700);
  });

  test('rejects invalid discounts', () {
    expect(
      () => BillingCalculator.calculate(
        originalAmount: 1000,
        discountType: DiscountType.percentage,
        discountValue: 101,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => BillingCalculator.calculate(
        originalAmount: 1000,
        discountType: DiscountType.fixed,
        discountValue: 1001,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test(
    'creates a pending invoice from completed appointment snapshots',
    () async {
      final repository = DemoRepository();
      final appointment = await repository.completeAppointment('appt_02');
      final invoice = await repository.createInvoice(
        appointmentId: appointment.id,
        discountType: DiscountType.percentage,
        discountValue: 10,
      );

      expect(invoice.paymentStatus, PaymentStatus.pending);
      expect(invoice.amountPaid, 0);
      expect(invoice.balance, invoice.total);
      expect(invoice.discountAmount, 420);
      expect(invoice.lineItems.single.originalPrice, 4200);
      expect(invoice.lineItems.single.serviceName, 'Balayage Refresh');
    },
  );

  test('does not duplicate an invoice for the same appointment', () async {
    final repository = DemoRepository();
    await repository.completeAppointment('appt_01');
    final first = await repository.createInvoice(
      appointmentId: 'appt_01',
      discountType: DiscountType.none,
      discountValue: 0,
    );
    final second = await repository.createInvoice(
      appointmentId: 'appt_01',
      discountType: DiscountType.fixed,
      discountValue: 100,
    );

    expect(second.id, first.id);
    expect(
      (await repository.getInvoices()).where(
        (invoice) => invoice.appointmentId == 'appt_01',
      ),
      hasLength(1),
    );
  });

  test('does not generate a bill before completion', () async {
    final repository = DemoRepository();
    final appointment = await repository.createAppointment(
      clientId: 'client_03',
      clientName: 'Aditi Shah',
      startAt: DateTime(2026, 9, 21, 15),
      services: [
        AppointmentService(
          id: 'billing_pending_service',
          serviceId: 'svc_01',
          serviceName: 'Signature Cut & Finish',
          durationMinutes: 60,
          price: 1800,
          employeeId: 'emp_01',
          employeeName: 'Aarohi Mehta',
        ),
      ],
    );

    await expectLater(
      repository.createInvoice(
        appointmentId: appointment.id,
        discountType: DiscountType.none,
        discountValue: 0,
      ),
      throwsA(isA<RepositoryException>()),
    );
  });
}
