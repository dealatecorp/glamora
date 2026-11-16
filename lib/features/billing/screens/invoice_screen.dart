import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../features/billing/domain/billing_calculator.dart';
import '../../../models/salon_models.dart';
import '../../payments/screens/payment_screen.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({
    super.key,
    required this.appointmentId,
    required this.repository,
  });

  final String appointmentId;
  final DemoRepository repository;

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  Appointment? _appointment;
  Invoice? _invoice;
  DiscountType _discountType = DiscountType.none;
  final _discountController = TextEditingController(text: '0');
  BillingQuote? _quote;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final appointment = await widget.repository.getAppointmentById(
        widget.appointmentId,
      );
      if (appointment == null) {
        throw const RepositoryException('Appointment was not found.');
      }
      final invoice = await widget.repository.getInvoiceByAppointmentId(
        widget.appointmentId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _appointment = appointment;
        _invoice = invoice;
        _isLoading = false;
      });
      if (invoice == null) {
        _calculate();
      }
    } on RepositoryException catch (exception) {
      if (mounted) {
        setState(() {
          _errorMessage = exception.message;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _calculate() async {
    if (_invoice != null) return;
    final value = double.tryParse(_discountController.text.trim());
    if (value == null) {
      setState(() => _errorMessage = 'Enter a valid discount.');
      return;
    }
    try {
      final quote = await widget.repository.calculateInvoice(
        appointmentId: widget.appointmentId,
        discountType: _discountType,
        discountValue: value,
      );
      if (mounted) {
        setState(() {
          _quote = quote;
          _errorMessage = null;
        });
      }
    } on FormatException catch (exception) {
      if (mounted) setState(() => _errorMessage = exception.message);
    } on RepositoryException catch (exception) {
      if (mounted) setState(() => _errorMessage = exception.message);
    }
  }

  Future<void> _createInvoice() async {
    final value = double.tryParse(_discountController.text.trim());
    if (value == null) {
      setState(() => _errorMessage = 'Enter a valid discount.');
      return;
    }
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final invoice = await widget.repository.createInvoice(
        appointmentId: widget.appointmentId,
        discountType: _discountType,
        discountValue: value,
      );
      if (!mounted) return;
      setState(() {
        _invoice = invoice;
        _quote = null;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice created successfully.')),
      );
    } on FormatException catch (exception) {
      if (mounted) {
        setState(() {
          _errorMessage = exception.message;
          _isSaving = false;
        });
      }
    } on RepositoryException catch (exception) {
      if (mounted) {
        setState(() {
          _errorMessage = exception.message;
          _isSaving = false;
        });
      }
    }
  }

  String _money(double value) => 'Rs ${value.toStringAsFixed(0)}';
  String _discountLabel() => _invoice == null
      ? (_discountType == DiscountType.percentage
            ? '${_discountController.text}%'
            : _money(double.tryParse(_discountController.text) ?? 0))
      : _money(_invoice!.discountAmount);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_appointment == null) {
      return Scaffold(
        body: EmptyState(
          title: 'Unable to generate invoice',
          subtitle: _errorMessage,
        ),
      );
    }
    final appointment = _appointment!;
    final invoice = _invoice;
    final quote = _quote;
    final original =
        invoice?.subtotal ?? quote?.originalAmount ?? appointment.totalPrice;
    final finalAmount = invoice?.total ?? quote?.finalAmount ?? original;
    final balance = invoice?.balance ?? quote?.balance ?? original;
    final lines =
        invoice?.lineItems ?? BillingCalculator.lineItemsFor(appointment);
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          if (invoice != null)
            IconButton(
              tooltip: 'Share invoice',
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Invoice sharing will be available with the sharing integration.',
                  ),
                ),
              ),
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Glamora', style: AppTextStyles.displaySmall),
                const SizedBox(height: 4),
                Text(
                  invoice?.invoiceNumber ?? 'Invoice review',
                  style: AppTextStyles.bodyMedium,
                ),
                Text(appointment.clientName, style: AppTextStyles.titleLarge),
                Text(
                  'Appointment ${appointment.id}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (invoice == null) ...[
            Text('Discount', style: AppTextStyles.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<DiscountType>(
                    initialValue: _discountType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(
                        value: DiscountType.none,
                        child: Text('None'),
                      ),
                      DropdownMenuItem(
                        value: DiscountType.percentage,
                        child: Text('Percentage'),
                      ),
                      DropdownMenuItem(
                        value: DiscountType.fixed,
                        child: Text('Fixed amount'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(
                        () => _discountType = value ?? DiscountType.none,
                      );
                      _calculate();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Value'),
                    onChanged: (_) => _calculate(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          Text('Services', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          AppCard(
            child: Column(
              children: lines
                  .map(
                    (line) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(line.serviceName),
                      subtitle: Text(
                        '${line.employeeName}  |  ${line.durationMinutes} min',
                      ),
                      trailing: Text(_money(line.finalAmount)),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              children: [
                _SummaryRow(label: 'Original amount', value: _money(original)),
                _SummaryRow(
                  label: 'Discount',
                  value: invoice == null
                      ? _discountLabel()
                      : _money(invoice.discountAmount),
                ),
                const Divider(),
                _SummaryRow(
                  label: 'Final amount',
                  value: _money(finalAmount),
                  emphasized: true,
                ),
                _SummaryRow(
                  label: 'Amount paid',
                  value: _money(invoice?.amountPaid ?? 0),
                ),
                _SummaryRow(
                  label: 'Balance',
                  value: _money(balance),
                  emphasized: true,
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
          const SizedBox(height: 18),
          if (invoice == null)
            PrimaryButton(
              label: 'Create invoice',
              isLoading: _isSaving,
              disabled: _isSaving,
              onPressed: _createInvoice,
            )
          else ...[
            StatusPill(
              label: invoice.paymentStatus.name,
              paymentStatus: invoice.paymentStatus,
            ),
            if (invoice.paymentMethod != null)
              Text(
                'Method: ${invoice.paymentMethod!.name}',
                style: AppTextStyles.bodySmall,
              ),
            if (invoice.transactionId != null)
              Text(
                'Reference: ${invoice.transactionId}',
                style: AppTextStyles.bodySmall,
              ),
            if (invoice.paymentDate != null)
              Text(
                'Paid: ${invoice.paymentDate}',
                style: AppTextStyles.bodySmall,
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    invoiceId: invoice.id,
                    repository: widget.repository,
                  ),
                ),
              ),
              child: const Text('Proceed to payment'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
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
