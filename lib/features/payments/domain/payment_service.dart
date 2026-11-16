import '../../../models/salon_models.dart';

class PaymentRequest {
  const PaymentRequest({
    required this.id,
    required this.invoiceId,
    required this.appointmentId,
    required this.clientId,
    required this.amount,
    required this.method,
    required this.reference,
    required this.qrPayload,
  });

  final String id;
  final String invoiceId;
  final String appointmentId;
  final String clientId;
  final double amount;
  final PaymentMethod method;
  final String reference;
  final String? qrPayload;
}

abstract class PaymentGateway {
  Future<PaymentRequest> createPaymentRequest({
    required Invoice invoice,
    required PaymentMethod method,
  });

  Future<String> verifyPayment({
    required PaymentRequest request,
    required String transactionReference,
  });

  Future<void> handleFailure({required PaymentRequest request, String? reason});

  Future<void> refundPayment({
    required Payment payment,
    required String refundReference,
  });
}

class MockPaymentGateway implements PaymentGateway {
  const MockPaymentGateway();

  @override
  Future<PaymentRequest> createPaymentRequest({
    required Invoice invoice,
    required PaymentMethod method,
  }) async {
    final requestId = 'request_${DateTime.now().millisecondsSinceEpoch}';
    return PaymentRequest(
      id: requestId,
      invoiceId: invoice.id,
      appointmentId: invoice.appointmentId,
      clientId: invoice.clientId,
      amount: invoice.total,
      method: method,
      reference: 'DEMO-$requestId',
      qrPayload: method == PaymentMethod.razorpay || method == PaymentMethod.upi
          ? 'upi://pay?pa=glamora@demo&am=${invoice.total.toStringAsFixed(2)}&tr=$requestId'
          : null,
    );
  }

  @override
  Future<String> verifyPayment({
    required PaymentRequest request,
    required String transactionReference,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final reference = transactionReference.trim();
    if (reference.isEmpty) {
      throw const PaymentException('Enter a payment reference to verify.');
    }
    if (!reference.startsWith('DEMO-')) {
      throw const PaymentException(
        'Payment could not be verified. Use a verified payment reference.',
      );
    }
    return reference;
  }

  @override
  Future<void> handleFailure({
    required PaymentRequest request,
    String? reason,
  }) async {}

  @override
  Future<void> refundPayment({
    required Payment payment,
    required String refundReference,
  }) async {
    if (refundReference.trim().isEmpty) {
      throw const PaymentException('A refund reference is required.');
    }
  }
}

class RazorpayPaymentGateway implements PaymentGateway {
  const RazorpayPaymentGateway();

  @override
  Future<PaymentRequest> createPaymentRequest({
    required Invoice invoice,
    required PaymentMethod method,
  }) {
    throw const PaymentException(
      'Razorpay orders must be created by the secure backend.',
    );
  }

  @override
  Future<String> verifyPayment({
    required PaymentRequest request,
    required String transactionReference,
  }) {
    throw const PaymentException(
      'Razorpay verification must be performed by the secure backend.',
    );
  }

  @override
  Future<void> handleFailure({
    required PaymentRequest request,
    String? reason,
  }) {
    throw const PaymentException(
      'Razorpay failure handling must be performed by the secure backend.',
    );
  }

  @override
  Future<void> refundPayment({
    required Payment payment,
    required String refundReference,
  }) {
    throw const PaymentException(
      'Razorpay refunds must be performed by the secure backend.',
    );
  }
}

class PaymentException implements Exception {
  const PaymentException(this.message);

  final String message;
}
