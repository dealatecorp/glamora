import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/features/payments/domain/payment_service.dart';
import 'package:saloon_application/models/salon_models.dart';

void main() {
  var sequence = 0;

  Future<(DemoRepository, Invoice, Payment)> createPendingPayment() async {
    final repository = DemoRepository();
    sequence += 1;
    final appointment = await repository.createAppointment(
      clientId: 'client_05',
      clientName: 'Tara Menon',
      startAt: DateTime(2027, 1, 10 + sequence, 10),
      services: [
        AppointmentService(
          id: 'payment_service',
          serviceId: 'svc_01',
          serviceName: 'Signature Cut & Finish',
          durationMinutes: 60,
          price: 1800,
          employeeId: 'emp_01',
          employeeName: 'Aarohi Mehta',
        ),
      ],
    );
    await repository.completeAppointment(appointment.id);
    final invoice = await repository.createInvoice(
      appointmentId: appointment.id,
      discountType: DiscountType.none,
      discountValue: 0,
    );
    final payment = await repository.createPaymentRecord(
      invoice: invoice,
      method: PaymentMethod.razorpay,
    );
    return (repository, invoice, payment);
  }

  test(
    'mock gateway stays pending until explicit verified reference',
    () async {
      final gateway = MockPaymentGateway();
      final invoice = Invoice(
        id: 'invoice_test',
        appointmentId: 'appointment_test',
        clientId: 'client_test',
        subtotal: 500,
        tax: 0,
        total: 500,
        issuedAt: DateTime(2027),
        isPaid: false,
      );
      final request = await gateway.createPaymentRequest(
        invoice: invoice,
        method: PaymentMethod.razorpay,
      );

      expect(request.amount, 500);
      expect(
        () => gateway.verifyPayment(
          request: request,
          transactionReference: 'invalid',
        ),
        throwsA(isA<PaymentException>()),
      );
      expect(
        await gateway.verifyPayment(
          request: request,
          transactionReference: request.reference,
        ),
        request.reference,
      );
    },
  );

  test(
    'verification updates payment, invoice, client XP, and VIP state',
    () async {
      final (repository, invoice, payment) = await createPendingPayment();
      expect(payment.status, PaymentStatus.pending);

      final verified = await repository.verifyPaymentRecord(
        paymentId: payment.id,
        transactionId: 'DEMO-verified-1',
      );
      final savedInvoice = await repository.getInvoiceById(invoice.id);
      final savedAppointment = await repository.getAppointmentById(
        invoice.appointmentId,
      );
      final client = await repository.getClientById('client_05');

      expect(verified.status, PaymentStatus.paid);
      expect(savedInvoice!.paymentStatus, PaymentStatus.paid);
      expect(savedInvoice.amountPaid, invoice.total);
      expect(savedInvoice.balance, 0);
      expect(savedInvoice.transactionId, 'DEMO-verified-1');
      expect(savedAppointment!.paymentStatus, PaymentStatus.paid);
      expect(client!.loyaltyPoints, 10);
      expect(client.visitCount, 1);
    },
  );

  test('failed and refunded states preserve references', () async {
    final (repository, invoice, payment) = await createPendingPayment();
    final failed = await repository.failPayment(
      paymentId: payment.id,
      reason: 'Customer cancelled the payment.',
    );
    expect(failed.status, PaymentStatus.failed);
    expect(failed.failureReason, isNotEmpty);

    final retry = await repository.verifyPaymentRecord(
      paymentId: payment.id,
      transactionId: 'DEMO-retry-1',
    );
    final refunded = await repository.refundPayment(
      paymentId: retry.id,
      refundReference: 'REFUND-1',
    );
    final savedInvoice = await repository.getInvoiceById(invoice.id);

    expect(refunded.status, PaymentStatus.refunded);
    expect(refunded.transactionId, 'DEMO-retry-1');
    expect(refunded.refundReference, 'REFUND-1');
    expect(savedInvoice!.paymentStatus, PaymentStatus.refunded);
  });
}
