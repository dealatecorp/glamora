import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../models/salon_models.dart';
import '../domain/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    super.key,
    required this.invoiceId,
    required this.repository,
    this.gateway = const MockPaymentGateway(),
  });

  final String invoiceId;
  final DemoRepository repository;
  final PaymentGateway gateway;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Invoice? _invoice;
  Payment? _payment;
  PaymentRequest? _request;
  PaymentMethod _method = PaymentMethod.razorpay;
  final _referenceController = TextEditingController();
  bool _isLoading = true;
  bool _isWorking = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final invoice = await widget.repository.getInvoiceById(widget.invoiceId);
      if (invoice == null) {
        throw const RepositoryException('Invoice was not found.');
      }
      final payment = await widget.repository.getPaymentByInvoiceId(invoice.id);
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _payment = payment;
        _isLoading = false;
      });
    } on RepositoryException catch (exception) {
      if (mounted) {
        setState(() {
          _errorMessage = exception.message;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _startPayment() async {
    final invoice = _invoice!;
    if (invoice.paymentStatus == PaymentStatus.paid) return;
    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });
    try {
      final request = await widget.gateway.createPaymentRequest(
        invoice: invoice,
        method: _method,
      );
      final payment = await widget.repository.createPaymentRecord(
        invoice: invoice,
        method: _method,
      );
      if (!mounted) return;
      setState(() {
        _request = request;
        _payment = payment;
        _isWorking = false;
        _referenceController.text =
            _method == PaymentMethod.razorpay || _method == PaymentMethod.upi
            ? ''
            : request.reference;
      });
    } on PaymentException catch (exception) {
      if (mounted) {
        setState(() {
          _errorMessage = exception.message;
          _isWorking = false;
        });
      }
    } on RepositoryException catch (exception) {
      if (mounted) {
        setState(() {
          _errorMessage = exception.message;
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _verify() async {
    final request = _request;
    final payment = _payment;
    if (request == null || payment == null) return;
    setState(() {
      _isWorking = true;
      _errorMessage = null;
    });
    try {
      final transactionId = await widget.gateway.verifyPayment(
        request: request,
        transactionReference: _referenceController.text,
      );
      final verified = await widget.repository.verifyPaymentRecord(
        paymentId: payment.id,
        transactionId: transactionId,
      );
      if (!mounted) return;
      setState(() {
        _payment = verified;
        _invoice = _invoice!.copyWithPayment(
          paymentStatus: PaymentStatus.paid,
          paymentMethod: _method,
          transactionId: transactionId,
          amountPaid: verified.amount,
          paymentDate: verified.paidAt ?? DateTime.now(),
        );
        _isWorking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment verified successfully.')),
      );
    } on PaymentException catch (exception) {
      if (mounted) {
        setState(() {
          _errorMessage = exception.message;
          _isWorking = false;
        });
      }
    } on RepositoryException catch (exception) {
      if (mounted) {
        setState(() {
          _errorMessage = exception.message;
          _isWorking = false;
        });
      }
    }
  }

  Future<void> _markFailed() async {
    final payment = _payment;
    if (payment == null) return;
    try {
      final failed = await widget.repository.failPayment(
        paymentId: payment.id,
        reason: 'Payment cancelled or failed by customer.',
      );
      if (mounted) {
        setState(() => _payment = failed);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment marked as failed.')),
        );
      }
    } on RepositoryException catch (exception) {
      if (mounted) setState(() => _errorMessage = exception.message);
    }
  }

  String _money(double amount) => 'Rs ${amount.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final invoice = _invoice;
    if (invoice == null) {
      return Scaffold(
        body: EmptyState(
          title: 'Unable to load payment',
          subtitle: _errorMessage,
        ),
      );
    }
    final isPaid =
        invoice.paymentStatus == PaymentStatus.paid ||
        _payment?.status == PaymentStatus.paid;
    final displayedPaymentStatus = isPaid
        ? PaymentStatus.paid
        : (_payment?.status ?? PaymentStatus.pending);
    final isPending =
        _payment == null || _payment!.status == PaymentStatus.pending;
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invoice.clientName, style: AppTextStyles.headlineMedium),
                const SizedBox(height: 4),
                Text(invoice.invoiceNumber, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 14),
                _AmountRow(
                  label: 'Original amount',
                  value: _money(invoice.subtotal),
                ),
                _AmountRow(
                  label: 'Discount',
                  value: _money(invoice.discountAmount),
                ),
                const Divider(),
                _AmountRow(
                  label: 'Payable amount',
                  value: _money(invoice.total),
                  emphasized: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Payment status', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          StatusPill(
            label: isPaid ? 'Paid' : (_payment?.status.name ?? 'Pending'),
            paymentStatus: displayedPaymentStatus,
          ),
          if (_payment?.transactionId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Reference: ${_payment!.transactionId}',
              style: AppTextStyles.bodySmall,
            ),
          ],
          if (!isPaid && isPending) ...[
            const SizedBox(height: 18),
            Text('Payment method', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Choose method'),
              items: const [
                DropdownMenuItem(
                  value: PaymentMethod.razorpay,
                  child: Text('Razorpay / UPI'),
                ),
                DropdownMenuItem(
                  value: PaymentMethod.cash,
                  child: Text('Cash'),
                ),
                DropdownMenuItem(
                  value: PaymentMethod.card,
                  child: Text('Card'),
                ),
                DropdownMenuItem(
                  value: PaymentMethod.manual,
                  child: Text('Other / Manual'),
                ),
              ],
              onChanged: (value) => setState(() {
                _method = value ?? PaymentMethod.razorpay;
                _request = null;
              }),
            ),
            const SizedBox(height: 14),
            if (_request == null)
              PrimaryButton(
                label: 'Generate payment request',
                isLoading: _isWorking,
                disabled: _isWorking,
                onPressed: _startPayment,
              )
            else ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _method == PaymentMethod.razorpay ||
                              _method == PaymentMethod.upi
                          ? 'Waiting for payment'
                          : 'Payment reference',
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (_request!.qrPayload != null) ...[
                      Container(
                        height: 150,
                        width: double.infinity,
                        alignment: Alignment.center,
                        color: AppColors.cream,
                        child: const Icon(Icons.qr_code_2_rounded, size: 100),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Pay exactly ${_money(_request!.amount)} using the secure payment request.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Demo verification reference: ${_request!.reference}',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _referenceController,
                      decoration: const InputDecoration(
                        labelText: 'Transaction/reference ID',
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Check payment',
                      isLoading: _isWorking,
                      disabled: _isWorking,
                      onPressed: _verify,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _markFailed,
                      child: const Text('Payment failed or cancelled'),
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: emphasized
                ? AppTextStyles.titleLarge
                : AppTextStyles.bodyMedium,
          ),
        ),
        Text(
          value,
          style: emphasized
              ? AppTextStyles.titleLarge.copyWith(
                  color: AppColors.champagneGold,
                )
              : AppTextStyles.bodyMedium,
        ),
      ],
    ),
  );
}
