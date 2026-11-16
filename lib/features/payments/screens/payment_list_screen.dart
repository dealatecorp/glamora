import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../features/auth/models/auth_role.dart';
import '../../../features/auth/models/auth_session.dart';
import '../../../models/salon_models.dart';
import 'payment_screen.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({
    super.key,
    required this.session,
    required this.repository,
    this.initialFilter = 'All',
  });

  final AuthSession session;
  final DemoRepository repository;
  final String initialFilter;

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  List<Payment> _payments = [];
  late String _filter;
  String _query = '';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _load();
  }

  Future<void> _load() async {
    try {
      final payments = await widget.repository.getPayments();
      if (!mounted) {
        return;
      }
      setState(() {
        _payments = payments;
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

  List<Payment> get _visible => _payments.where((payment) {
    final statusMatch =
        _filter == 'All' || payment.status.name == _filter.toLowerCase();
    final queryMatch =
        _query.isEmpty ||
        '${payment.id} ${payment.transactionId ?? ''} ${payment.method.name} ${payment.status.name}'
            .toLowerCase()
            .contains(_query);
    return statusMatch && queryMatch;
  }).toList();

  PaymentStatus? _statusForFilter(String filter) {
    for (final status in PaymentStatus.values) {
      if (status.name == filter.toLowerCase()) return status;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: const Text('Payments')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text('Payment activity', style: AppTextStyles.displaySmall),
              const SizedBox(height: 6),
              Text(
                widget.session.role == AuthRole.admin
                    ? 'Review payment states and references.'
                    : 'Operational payment status for your workday.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 18),
              SearchField(
                hintText: 'Search reference or method',
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['All', 'Pending', 'Paid', 'Failed', 'Refunded']
                    .map(
                      (filter) {
                        final status = _statusForFilter(filter);
                        return ChoiceChip(
                          label: status == null
                              ? Text(filter)
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PaymentStatusDot(status: status),
                                    const SizedBox(width: 6),
                                    Text(filter),
                                  ],
                                ),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                          selectedColor: AppColors.cream,
                          side: BorderSide(
                            color: _filter == filter
                                ? AppColors.champagneGold
                                : AppColors.border,
                          ),
                        );
                      },
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                EmptyState(
                  title: 'Unable to load payments',
                  subtitle: _errorMessage,
                )
              else if (visible.isEmpty)
                const EmptyState(title: 'No payments found.')
              else
                ...visible.map(
                  (payment) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PaymentCard(
                      payment: payment,
                      showAmount: widget.session.isAdmin,
                      onTap: payment.invoiceId.isEmpty
                          ? null
                          : () async {
                              final invoice = await widget.repository
                                  .getInvoiceById(payment.invoiceId);
                              if (invoice != null && context.mounted) {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => PaymentScreen(
                                      invoiceId: invoice.id,
                                      repository: widget.repository,
                                    ),
                                  ),
                                );
                                _load();
                              }
                            },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.onTap,
    required this.showAmount,
  });

  final Payment payment;
  final VoidCallback? onTap;
  final bool showAmount;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: AppColors.champagneGold,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.method.name.toUpperCase(),
                  style: AppTextStyles.titleLarge,
                ),
                Text(
                  payment.transactionId ?? payment.id,
                  style: AppTextStyles.bodySmall,
                ),
                if (showAmount)
                  Text(
                    'Rs ${payment.amount.toStringAsFixed(0)}',
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
          StatusPill(label: payment.status.name, paymentStatus: payment.status),
        ],
      ),
    ),
  );
}
