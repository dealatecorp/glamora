import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../features/appointments/domain/appointment_scheduler.dart';
import '../../../features/billing/screens/invoice_screen.dart';
import '../../../features/auth/models/auth_session.dart';
import '../../../models/salon_models.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
    required this.repository,
    this.session,
  });

  final String appointmentId;
  final DemoRepository repository;
  final AuthSession? session;

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  Appointment? _appointment;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final appointment = await widget.repository.getAppointmentById(
        widget.appointmentId,
      );
      if (appointment == null) {
        throw const RepositoryException('Appointment was not found.');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _appointment = appointment;
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

  bool get _canChange =>
      (widget.session?.isAdmin ?? true) &&
      _appointment != null &&
      _appointment!.status != AppointmentStatus.completed &&
      _appointment!.status != AppointmentStatus.cancelled &&
      _appointment!.status != AppointmentStatus.noShow;

  Future<void> _reschedule() async {
    final appointment = _appointment!;
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      initialDate: appointment.startAt.isBefore(DateTime.now())
          ? DateTime.now()
          : appointment.startAt,
    );
    if (selectedDate == null || !mounted) return;
    final drafts = appointment.services.map(
      (service) => AppointmentDraftService(
        service: Service(
          id: service.serviceId,
          name: service.serviceName,
          description: '',
          durationMinutes: service.durationMinutes,
          price: service.price,
          category: service.category ?? ServiceCategory.hair,
          isActive: true,
          createdAt: appointment.createdAt,
          assignedEmployeeIds: service.employeeId == null
              ? const []
              : [service.employeeId!],
        ),
        employeeId: service.employeeId ?? '',
        employeeName: service.employeeName ?? 'Employee',
      ),
    );
    final businessHours = await widget.repository.getBusinessHours();
    final salonBreaks = await widget.repository.getSalonBreaks();
    final slots = AppointmentScheduler.availableSlots(
      date: selectedDate,
      services: drafts,
      appointments: DemoData.appointments
          .where((item) => item.id != appointment.id)
          .toList(),
      businessHours: businessHours,
      salonBreaks: salonBreaks,
    );
    if (!mounted) return;
    if (slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available time slots for this selection.'),
        ),
      );
      return;
    }
    final selectedSlot = await showDialog<DateTime>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose a new time'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: slots
                .map(
                  (slot) => ActionChip(
                    label: Text(_time(slot)),
                    onPressed: () => Navigator.pop(context, slot),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (selectedSlot == null) return;
    final updated = Appointment(
      id: appointment.id,
      clientId: appointment.clientId,
      clientName: appointment.clientName,
      employeeId: appointment.employeeId,
      employeeName: appointment.employeeName,
      startAt: selectedSlot,
      endAt: AppointmentScheduler.endAt(selectedSlot, drafts),
      status: appointment.status,
      services: appointment.services,
      notes: appointment.notes,
      source: appointment.source,
      createdAt: appointment.createdAt,
      updatedAt: DateTime.now(),
      createdBy: appointment.createdBy,
      reminder: appointment.reminder,
    );
    try {
      await widget.repository.updateAppointment(updated);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment rescheduled.')),
        );
      }
    } on RepositoryException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    }
  }

  Future<void> _cancel() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel appointment'),
        content: TextField(
          controller: reasonController,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Cancellation reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    reasonController.dispose();
    if (confirmed != true) return;
    try {
      await widget.repository.cancelAppointment(
        id: widget.appointmentId,
        reason: reason,
        cancelledBy: 'demo',
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appointment cancelled.')));
      }
    } on RepositoryException catch (exception) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(exception.message)));
      }
    }
  }

  Future<void> _changeStatus(AppointmentStatus status) async {
    try {
      if (status == AppointmentStatus.noShow) {
        await widget.repository.markNoShow(widget.appointmentId);
      }
      if (status == AppointmentStatus.completed) {
        await widget.repository.completeAppointment(widget.appointmentId);
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == AppointmentStatus.noShow
                  ? 'Appointment marked No Show.'
                  : 'Appointment completed.',
            ),
          ),
        );
        if (status == AppointmentStatus.completed) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InvoiceScreen(
                appointmentId: widget.appointmentId,
                repository: widget.repository,
              ),
            ),
          );
        }
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
    if (_appointment == null) {
      return Scaffold(
        body: EmptyState(
          title: 'Unable to load appointment',
          subtitle: _errorMessage,
        ),
      );
    }
    final appointment = _appointment!;
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: const Text('Appointment details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        appointment.clientName,
                        style: AppTextStyles.headlineMedium,
                      ),
                    ),
                    StatusPill(
                      label: appointment.status == AppointmentStatus.noShow
                          ? 'No Show'
                          : appointment.status.name,
                      appointmentStatus: appointment.status,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${_date(appointment.startAt)}  |  ${_time(appointment.startAt)} - ${_time(appointment.endAt)}',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 12),
                ...appointment.services.map(
                  (service) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      service.historicalServiceName ?? service.serviceName,
                    ),
                    subtitle: Text(
                      '${service.durationMinutes} min  |  ${service.employeeName ?? 'Unassigned'}',
                    ),
                    trailing: Text('Rs ${service.price.toStringAsFixed(0)}'),
                  ),
                ),
              ],
            ),
          ),
          if (appointment.status == AppointmentStatus.completed) ...[
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Generate bill',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InvoiceScreen(
                    appointmentId: appointment.id,
                    repository: widget.repository,
                  ),
                ),
              ),
            ),
          ],
          if (appointment.reminder != null) ...[
            const SizedBox(height: 12),
            Text('Reminder', style: AppTextStyles.titleLarge),
            AppCard(child: Text(appointment.reminder!.title)),
          ],
          if (_canChange) ...[
            const SizedBox(height: 20),
            PrimaryButton(label: 'Reschedule', onPressed: _reschedule),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Mark completed',
              onPressed: () => _changeStatus(AppointmentStatus.completed),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _changeStatus(AppointmentStatus.noShow),
              child: const Text('Mark No Show'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _cancel,
              child: const Text('Cancel appointment'),
            ),
          ],
        ],
      ),
    );
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
