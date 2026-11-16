import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../auth/models/auth_role.dart';
import '../../auth/models/auth_session.dart';
import '../domain/client_rules.dart';
import '../../../models/salon_models.dart';
import 'client_form_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  const ClientDetailsScreen({
    super.key,
    required this.clientId,
    required this.repository,
    required this.session,
  });

  final String clientId;
  final ClientRepository repository;
  final AuthSession? session;

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  Client? _client;
  ClientHistory? _history;
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isAdmin => widget.session?.role == AuthRole.admin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final client = await widget.repository.getClientById(widget.clientId);
      if (client == null) {
        throw const RepositoryException('Client was not found.');
      }
      final history = await widget.repository.getClientHistory(widget.clientId);
      if (!mounted) return;
      setState(() {
        _client = client;
        _history = history;
        _isLoading = false;
      });
    } on RepositoryException catch (exception) {
      if (!mounted) return;
      setState(() {
        _errorMessage = exception.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ClientFormScreen(repository: widget.repository, client: _client),
      ),
    );
    if (changed == true) {
      await _load();
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _changeXp() async {
    final amountController = TextEditingController();
    final isAdding = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust loyalty XP'),
        content: TextField(
          controller: amountController,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          decoration: const InputDecoration(hintText: 'Amount, e.g. 50 or -20'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Update'),
          ),
        ],
      ),
    );
    final amount = int.tryParse(amountController.text.trim());
    amountController.dispose();
    if (isAdding != true || amount == null || amount == 0) return;
    try {
      await widget.repository.updateLoyaltyXp(widget.clientId, amount);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Loyalty XP updated.')));
      }
    } on RepositoryException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    }
  }

  Future<void> _toggleArchive() async {
    final isArchived = _client!.isArchived;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isArchived ? 'Restore client?' : 'Archive client?'),
        content: Text(
          isArchived
              ? 'This client will return to the active list.'
              : 'History will be preserved and the client removed from active lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isArchived ? 'Restore' : 'Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (isArchived) {
      await widget.repository.restoreClient(widget.clientId);
    } else {
      await widget.repository.archiveClient(widget.clientId);
    }
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isArchived ? 'Client restored.' : 'Client archived.'),
        ),
      );
      if (!isArchived) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _deleteClient() async {
    final client = _client!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete client permanently?'),
        content: Text(
          '${client.fullName} will be permanently removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deleteClient(widget.clientId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Client deleted.')));
        Navigator.of(context).pop(true);
      }
    } on RepositoryException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null || _client == null || _history == null) {
      return Scaffold(
        body: EmptyState(
          title: 'Unable to load client',
          subtitle: _errorMessage,
        ),
      );
    }
    final client = _client!;
    final history = _history!;
    final calculatedVisits = ClientRules.completedPaidVisitCount(history);
    final calculatedVip = ClientRules.isVipFromHistory(history);
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: const Text('Client profile'),
        actions: [
          IconButton(
            tooltip: 'Edit client',
            onPressed: _edit,
            icon: const Icon(Icons.edit_outlined),
          ),
          if (_isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteClient();
                  return;
                }
                _toggleArchive();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'archive',
                  child: Text(
                    client.isArchived ? 'Restore client' : 'Archive client',
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete client'),
                ),
              ],
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _ProfileHeader(client: client, isVip: calculatedVip),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Paid visits',
                    value: '$calculatedVisits',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Metric(
                    label: 'Loyalty XP',
                    value: '${client.loyaltyPoints}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: 'Adjust loyalty XP', onPressed: _changeXp),
            const SizedBox(height: 20),
            _Section(
              title: 'Appointment history',
              child: history.appointments.isEmpty
                  ? const EmptyState(title: 'No appointment history yet.')
                  : Column(
                      children: history.appointments
                          .map(_appointmentTile)
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Service history',
              child: history.services.isEmpty
                  ? const EmptyState(title: 'No service history yet.')
                  : Column(
                      children: history.services.map(_serviceTile).toList(),
                    ),
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Billing and payments',
              child: history.payments.isEmpty && history.invoices.isEmpty
                  ? const EmptyState(title: 'No payment history yet.')
                  : Column(
                      children: [
                        ...history.payments.map(_paymentTile),
                        if (_isAdmin) ...history.invoices.map(_invoiceTile),
                      ],
                    ),
            ),
            if (!_isAdmin && history.payments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Payment status is shown for operational access. Financial totals are restricted to admins.',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _appointmentTile(Appointment appointment) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.event_outlined, color: AppColors.champagneGold),
    title: Text('${_date(appointment.startAt)}  ${_time(appointment.startAt)}'),
    subtitle: Text(
      '${appointment.services.map((service) => service.serviceName).join(', ')}\n${appointment.employeeName ?? 'Unassigned'}',
    ),
    isThreeLine: true,
    trailing: StatusPill(
      label: appointment.status.name,
      appointmentStatus: appointment.status,
    ),
  );

  Widget _serviceTile(AppointmentService service) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(
      Icons.content_cut_rounded,
      color: AppColors.champagneGold,
    ),
    title: Text(service.historicalServiceName ?? service.serviceName),
    subtitle: Text(
      '${service.historicalDurationMinutes ?? service.durationMinutes} min  |  ${service.employeeName ?? 'Team'}',
    ),
    trailing: _isAdmin
        ? Text(
            'Rs ${service.historicalPrice ?? service.price}',
            style: AppTextStyles.labelLarge,
          )
        : null,
  );

  Widget _paymentTile(Payment payment) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(
      Icons.receipt_long_outlined,
      color: AppColors.champagneGold,
    ),
    title: Text(payment.receiptNumber ?? payment.id),
    subtitle: Text('${_date(payment.createdAt)}  |  ${payment.method.name}'),
    trailing: _isAdmin
        ? StatusPill(
            label: '${payment.status.name}  Rs ${payment.amount}',
            paymentStatus: payment.status,
          )
        : StatusPill(
            label: payment.status.name,
            paymentStatus: payment.status,
          ),
  );

  Widget _invoiceTile(Invoice invoice) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(invoice.id),
    subtitle: Text(
      'Issued ${_date(invoice.issuedAt)}  |  Total Rs ${invoice.total}',
    ),
    trailing: StatusPill(
      label: invoice.paymentStatus.name,
      paymentStatus: invoice.paymentStatus,
    ),
  );

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.client, required this.isVip});

  final Client client;
  final bool isVip;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(client.fullName, style: AppTextStyles.headlineMedium),
            ),
            if (isVip) const StatusPill(label: 'VIP'),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          client.phone ?? 'No mobile number',
          style: AppTextStyles.bodyMedium,
        ),
        if (client.email != null)
          Text(client.email!, style: AppTextStyles.bodySmall),
        if (client.isArchived) ...[
          const SizedBox(height: 8),
          const StatusPill(label: 'Archived'),
        ],
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.headlineMedium),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: AppTextStyles.titleLarge),
      const SizedBox(height: 8),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: child,
      ),
    ],
  );
}
