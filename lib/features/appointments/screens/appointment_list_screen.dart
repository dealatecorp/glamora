import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../features/auth/models/auth_session.dart';
import '../../../models/salon_models.dart';
import 'appointment_booking_screen.dart';
import 'appointment_details_screen.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({
    super.key,
    required this.session,
    required this.repository,
  });

  final AuthSession? session;
  final DemoRepository repository;

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  final _searchController = TextEditingController();
  List<Appointment> _appointments = [];
  String _filter = 'Today';
  bool _isLoading = true;
  String? _errorMessage;

  final _filters = const [
    'Today',
    'Upcoming',
    'Completed',
    'Cancelled',
    'No Show',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final appointments = await widget.repository.getAppointments();
      if (!mounted) return;
      setState(() {
        _appointments = widget.session?.isEmployee == true
            ? appointments
                  .where(
                    (appointment) => appointment.services.any(
                      (service) =>
                          service.employeeId == widget.session!.employeeId,
                    ),
                  )
                  .toList()
            : appointments;
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

  bool _matchesFilter(Appointment appointment) {
    final now = DateTime.now();
    final sameDay =
        appointment.startAt.year == now.year &&
        appointment.startAt.month == now.month &&
        appointment.startAt.day == now.day;
    switch (_filter) {
      case 'Today':
        return sameDay &&
            appointment.status != AppointmentStatus.cancelled &&
            appointment.status != AppointmentStatus.noShow;
      case 'Upcoming':
        return appointment.startAt.isAfter(now) &&
            appointment.status != AppointmentStatus.completed &&
            appointment.status != AppointmentStatus.cancelled &&
            appointment.status != AppointmentStatus.noShow;
      case 'Completed':
        return appointment.status == AppointmentStatus.completed;
      case 'Cancelled':
        return appointment.status == AppointmentStatus.cancelled;
      case 'No Show':
        return appointment.status == AppointmentStatus.noShow;
      default:
        return true;
    }
  }

  List<Appointment> get _visibleAppointments {
    final query = _searchController.text.trim().toLowerCase();
    return _appointments.where((appointment) {
      if (!_matchesFilter(appointment)) return false;
      final searchable = [
        appointment.clientName,
        DemoData.clients
                .where((client) => client.id == appointment.clientId)
                .map((client) => client.phone ?? '')
                .firstOrNull ??
            '',
        appointment.startAt.toIso8601String(),
        appointment.status.name,
        appointment.employeeName ?? '',
        ...appointment.services.map((service) => service.serviceName),
      ].join(' ').toLowerCase();
      return query.isEmpty || searchable.contains(query);
    }).toList();
  }

  bool get _showCreateForCurrentFilter =>
      _filter != 'Completed' && _filter != 'Cancelled' && _filter != 'No Show';

  Future<void> _book() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AppointmentBookingScreen(
          repository: widget.repository,
          session: widget.session,
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleAppointments;
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          if (_showCreateForCurrentFilter)
          IconButton(
            tooltip: 'New appointment',
            onPressed: _book,
            icon: const Icon(Icons.add_alarm_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text('Schedule', style: AppTextStyles.displaySmall),
              const SizedBox(height: 6),
              Text(
                'Keep every visit calm, clear, and conflict-free.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 18),
              SearchField(
                hintText: 'Search client, service, employee, date...',
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _filters
                      .map(
                        (filter) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: filter == 'Cancelled'
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const AppointmentStatusDot(
                                        status: AppointmentStatus.cancelled,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(filter),
                                    ],
                                  )
                                : Text(filter),
                            selected: _filter == filter,
                            onSelected: (_) => setState(() => _filter = filter),
                            selectedColor: AppColors.cream,
                            side: BorderSide(
                              color: _filter == filter
                                  ? AppColors.champagneGold
                                  : AppColors.border,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                EmptyState(
                  title: 'Unable to load appointments',
                  subtitle: _errorMessage,
                )
              else if (visible.isEmpty)
                EmptyState(
                  title: 'No appointments ${_filter.toLowerCase()}.',
                  subtitle: _searchController.text.isEmpty
                      ? null
                      : 'Try a different search.',
                )
              else
                ...visible.map(
                  (appointment) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AppointmentCard(
                      appointment: appointment,
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => AppointmentDetailsScreen(
                              appointmentId: appointment.id,
                              repository: widget.repository,
                              session: widget.session,
                            ),
                          ),
                        );
                        if (changed == true) _load();
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              if (_showCreateForCurrentFilter)
                PrimaryButton(label: 'Create appointment', onPressed: _book),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment, required this.onTap});

  final Appointment appointment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = appointment.status == AppointmentStatus.noShow
        ? 'No Show'
        : appointment.status.name;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Text(
                    '${appointment.startAt.day}',
                    style: AppTextStyles.titleLarge,
                  ),
                  Text(
                    _month(appointment.startAt.month),
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appointment.clientName, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${_time(appointment.startAt)} - ${_time(appointment.endAt)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    appointment.services
                        .map((service) => service.serviceName)
                        .join(', '),
                    style: AppTextStyles.caption,
                  ),
                  if (appointment.employeeName != null)
                    Text(
                      appointment.employeeName!,
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
            StatusPill(label: status, appointmentStatus: appointment.status),
          ],
        ),
      ),
    );
  }
}

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];
