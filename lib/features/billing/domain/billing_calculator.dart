import '../../../models/salon_models.dart';

class BillingQuote {
  const BillingQuote({
    required this.originalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.balance,
  });

  final double originalAmount;
  final double discountAmount;
  final double finalAmount;
  final double balance;
}

class BillingCalculator {
  const BillingCalculator._();

  static BillingQuote calculate({
    required double originalAmount,
    required DiscountType discountType,
    required double discountValue,
    double amountPaid = 0,
  }) {
    if (originalAmount < 0) {
      throw const FormatException('Original amount cannot be negative.');
    }
    if (discountValue < 0) {
      throw const FormatException('Discount cannot be negative.');
    }
    final double discountAmount = switch (discountType) {
      DiscountType.none => 0,
      DiscountType.percentage => originalAmount * discountValue / 100,
      DiscountType.fixed => discountValue,
    };
    if (discountType == DiscountType.percentage && discountValue > 100) {
      throw const FormatException('Percentage discount cannot exceed 100%.');
    }
    if (discountAmount > originalAmount) {
      throw const FormatException('Discount cannot exceed the bill amount.');
    }
    if (amountPaid < 0 || amountPaid > originalAmount - discountAmount) {
      throw const FormatException('Amount paid is invalid.');
    }
    final finalAmount = originalAmount - discountAmount;
    return BillingQuote(
      originalAmount: originalAmount,
      discountAmount: discountAmount,
      finalAmount: finalAmount,
      balance: finalAmount - amountPaid,
    );
  }

  static List<InvoiceLineItem> lineItemsFor(Appointment appointment) {
    return appointment.services
        .map(
          (service) => InvoiceLineItem(
            serviceName: service.historicalServiceName ?? service.serviceName,
            employeeName: service.employeeName ?? 'Unassigned',
            durationMinutes:
                service.historicalDurationMinutes ?? service.durationMinutes,
            originalPrice: service.historicalPrice ?? service.price,
            discountAmount: 0,
            finalAmount: service.historicalPrice ?? service.price,
          ),
        )
        .toList();
  }
}
