import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../features/auth/models/auth_session.dart';
import '../../../models/salon_models.dart';
import 'employee_form_screen.dart';

class EmployeeDetailsScreen extends StatefulWidget {
  const EmployeeDetailsScreen({
    super.key,
    required this.employeeId,
    required this.repository,
    this.session,
  });

  final String employeeId;
  final DemoRepository repository;
  final AuthSession? session;

  @override
  State<EmployeeDetailsScreen> createState() => _EmployeeDetailsScreenState();
}

class _EmployeeDetailsScreenState extends State<EmployeeDetailsScreen> {
  Employee? _employee;
  List<Service> _services = [];
  List<Appointment> _appointments = [];
  List<EmployeeRewardTransaction> _rewards = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.session?.isEmployee == true &&
          widget.session!.employeeId != widget.employeeId) {
        throw const RepositoryException(
          'You can only view your own employee profile.',
        );
      }
      final employee = await widget.repository.getEmployeeById(
        widget.employeeId,
      );
      if (employee == null) {
        throw const RepositoryException('Employee was not found.');
      }
      final services = await widget.repository.getServices(
        includeArchived: true,
      );
      final appointments = await widget.repository.getEmployeeAppointments(
        widget.employeeId,
      );
      final rewards = await widget.repository.getEmployeeRewardHistory(
        widget.employeeId,
      );
      if (!mounted) return;
      setState(() {
        _employee = employee;
        _services = services;
        _appointments = appointments;
        _rewards = rewards;
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

  Future<void> _edit() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EmployeeFormScreen(
          repository: widget.repository,
          employee: _employee,
        ),
      ),
    );
    if (changed == true) _load();
  }

  Future<void> _toggleArchive() async {
    final employee = _employee!;
    final restore = !employee.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(restore ? 'Restore employee?' : 'Archive employee?'),
        content: Text(
          restore
              ? 'This employee will return to future assignment lists.'
              : 'Historical appointments and profile data will remain available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(restore ? 'Restore' : 'Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (restore) {
      await widget.repository.restoreEmployee(employee.id);
    } else {
      await widget.repository.archiveEmployee(employee.id);
    }
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(restore ? 'Employee restored.' : 'Employee archived.'),
        ),
      );
    }
  }

  Future<void> _adjustXp() async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust employee XP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(labelText: 'Reason'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final amount = int.tryParse(amountController.text.trim());
    final reason = reasonController.text.trim();
    amountController.dispose();
    reasonController.dispose();
    if (confirmed != true || amount == null || amount == 0 || reason.isEmpty)
      return;
    try {
      await widget.repository.adjustEmployeeXp(
        employeeId: widget.employeeId,
        amount: amount,
        reason: reason,
        performedBy: 'admin',
      );
      await _load();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Employee XP updated.')));
    } on RepositoryException catch (exception) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  Future<void> _resetPin() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset employee PIN'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New PIN/password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    try {
      await widget.repository.resetEmployeePin(widget.employeeId, value);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Employee PIN reset.')));
    } on RepositoryException catch (exception) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final employee = _employee;
    if (employee == null)
      return Scaffold(
        body: EmptyState(
          title: 'Unable to load employee',
          subtitle: _errorMessage,
        ),
      );
    final capabilities = _services
        .where((service) => employee.serviceIds.contains(service.id))
        .toList();
    final completed = _appointments
        .where(
          (appointment) => appointment.status == AppointmentStatus.completed,
        )
        .length;
    final clientsServed = _appointments
        .where(
          (appointment) => appointment.status == AppointmentStatus.completed,
        )
        .map((appointment) => appointment.clientId)
        .toSet()
        .length;
    final upcoming = _appointments
        .where(
          (appointment) =>
              appointment.startAt.isAfter(DateTime.now()) &&
              appointment.status != AppointmentStatus.cancelled &&
              appointment.status != AppointmentStatus.noShow,
        )
        .length;
    final cancelled = _appointments
        .where(
          (appointment) => appointment.status == AppointmentStatus.cancelled,
        )
        .length;
    final noShows = _appointments
        .where((appointment) => appointment.status == AppointmentStatus.noShow)
        .length;
    final servicesPerformed = _appointments
        .where(
          (appointment) => appointment.status == AppointmentStatus.completed,
        )
        .expand((appointment) => appointment.services)
        .where((service) => service.employeeId == employee.id)
        .length;
    final canManage = widget.session?.isEmployee != true;
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: const Text('Employee profile'),
        actions: [
          if (canManage)
            IconButton(
              tooltip: 'Edit employee',
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (canManage)
            IconButton(
              tooltip: employee.isActive
                  ? 'Archive employee'
                  : 'Restore employee',
              onPressed: _toggleArchive,
              icon: Icon(
                employee.isActive
                    ? Icons.archive_outlined
                    : Icons.unarchive_outlined,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _ProfileCard(employee: employee),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Clients served',
                  value: '$clientsServed',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(label: 'Completed', value: '$completed'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(label: 'XP', value: '${employee.rewardXp}'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Metric(label: 'Upcoming', value: '$upcoming'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(label: 'Cancelled', value: '$cancelled'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Metric(
                  label: 'No-show / services',
                  value: '$noShows / $servicesPerformed',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Service capabilities',
            child: capabilities.isEmpty
                ? const Text('No capabilities assigned.')
                : Column(
                    children: capabilities
                        .map(
                          (service) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(service.name),
                            subtitle: Text(service.category.label),
                            trailing: StatusPill(
                              label: service.isActive ? 'Active' : 'Archived',
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Appointment history',
            child: _appointments.isEmpty
                ? const Text('No appointment history yet.')
                : Column(
                    children: _appointments
                        .map(
                          (appointment) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(appointment.clientName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_date(appointment.startAt)}  |  ${appointment.services.map((service) => service.serviceName).join(', ')}',
                                ),
                                _PaymentStatusLine(
                                  status: appointment.paymentStatus,
                                ),
                              ],
                            ),
                            trailing: StatusPill(
                              label:
                                  appointment.status == AppointmentStatus.noShow
                                  ? 'No Show'
                                  : appointment.status.name,
                              appointmentStatus: appointment.status,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
          const SizedBox(height: 14),
          _Section(
            title: 'Rewards and XP',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${employee.rewardXp} XP balance',
                  style: AppTextStyles.titleLarge,
                ),
                const SizedBox(height: 8),
                if (_rewards.isEmpty)
                  const Text('No reward history yet.')
                else
                  ..._rewards.reversed.map(
                    (reward) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '${reward.amount > 0 ? '+' : ''}${reward.amount} XP',
                      ),
                      subtitle: Text(
                        '${reward.reason}  |  by ${reward.performedBy}',
                      ),
                      trailing: Text(_date(reward.createdAt)),
                    ),
                  ),
                if (canManage) ...[
                  const SizedBox(height: 8),
                  PrimaryButton(label: 'Adjust XP', onPressed: _adjustXp),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (canManage)
            PrimaryButton(
              label: employee.isActive ? 'Reset PIN' : 'Employee archived',
              disabled: !employee.isActive,
              onPressed: employee.isActive ? _resetPin : null,
            ),
        ],
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.employee});
  final Employee employee;
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                employee.fullName,
                style: AppTextStyles.headlineMedium,
              ),
            ),
            StatusPill(
              label: employee.isActive ? 'Active' : 'Archived',
              showSuccessDot: employee.isActive,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(employee.id, style: AppTextStyles.bodyMedium),
        Text(
          employee.phone ?? 'No mobile number',
          style: AppTextStyles.bodySmall,
        ),
        if (employee.email != null)
          Text(employee.email!, style: AppTextStyles.bodySmall),
        Text(
          '${employee.experienceYears} years experience',
          style: AppTextStyles.caption,
        ),
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
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.titleLarge),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: child,
      ),
    ],
  );
}

class _PaymentStatusLine extends StatelessWidget {
  const _PaymentStatusLine({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Text('Payment: '),
      PaymentStatusDot(status: status),
      const SizedBox(width: 6),
      Text(status.name),
    ],
  );
}
