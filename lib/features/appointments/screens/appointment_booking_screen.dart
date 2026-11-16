import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/repositories.dart';
import '../../../features/appointments/domain/appointment_scheduler.dart';
import '../../../features/auth/models/auth_session.dart';
import '../../../features/clients/screens/client_form_screen.dart';
import '../../../models/salon_models.dart';

class AppointmentBookingScreen extends StatefulWidget {
  const AppointmentBookingScreen({
    super.key,
    required this.repository,
    this.session,
  });

  final DemoRepository repository;
  final AuthSession? session;

  @override
  State<AppointmentBookingScreen> createState() =>
      _AppointmentBookingScreenState();
}

class _AppointmentBookingScreenState extends State<AppointmentBookingScreen> {
  int _step = 0;
  List<Client> _clients = [];
  List<Service> _services = [];
  List<Employee> _employees = [];
  Client? _client;
  String? _clientId;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;
  late final FocusNode _mobileFocusNode;
  late final FocusNode _emailFocusNode;
  String? _mobileError;
  String? _emailError;
  final Set<String> _selectedServiceIds = {};
  final Map<String, String> _employeeByService = {};
  final Set<String> _overriddenServiceIds = {};
  ServiceCategory? _serviceCategory;
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  DateTime? _startAt;
  String _reminder = 'No reminder';
  List<DateTime> _availableSlots = [];
  List<BusinessHours> _businessHours = [];
  List<SalonBreak> _salonBreaks = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  List<Service> get _selectedServices => _services
      .where((service) => _selectedServiceIds.contains(service.id))
      .toList();

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController();
    _emailController = TextEditingController();
    _mobileFocusNode = FocusNode()..addListener(_validateContactFields);
    _emailFocusNode = FocusNode()..addListener(_validateContactFields);
    _loadData();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _emailController.dispose();
    _mobileFocusNode
      ..removeListener(_validateContactFields)
      ..dispose();
    _emailFocusNode
      ..removeListener(_validateContactFields)
      ..dispose();
    super.dispose();
  }

  void _validateContactFields() {
    if (!_mobileFocusNode.hasFocus) {
      _validateMobileNumber();
    }
    if (!_emailFocusNode.hasFocus) {
      final value = _emailController.text.trim();
      setState(() {
        _emailError = _emailValidationError(value);
      });
    }
  }

  void _validateMobileNumber() {
    final value = _mobileController.text.trim();
    if (!mounted) return;
    setState(() {
      _mobileError = _mobileValidationError(value);
    });
  }

  String? _mobileValidationError(String value) {
    return RegExp(r'^\d{10}$').hasMatch(value)
        ? null
        : 'Mobile number must be exactly 10 digits.';
  }

  String? _emailValidationError(String value) =>
      _isValidEmail(value) ? null : 'Enter a valid email address.';

  bool _isValidEmail(String value) =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);

  void _selectClient(Client? client) {
    setState(() {
      _client = client;
      _clientId = client?.id;
      _mobileController.text = _normalizedPhone(client?.phone);
      _emailController.text = client?.email ?? '';
      _mobileError = null;
      _emailError = null;
    });
  }

  String _normalizedPhone(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
  }

  Future<void> _loadData() async {
    try {
      final clients = await widget.repository.getClients();
      final services = await widget.repository.getServices();
      final employees = await widget.repository.getEmployees();
      final businessHours = await widget.repository.getBusinessHours();
      final salonBreaks = await widget.repository.getSalonBreaks();
      if (!mounted) {
        return;
      }
      final activeClients = _uniqueActiveClients(clients);
      final selectedClient = _clientId == null
          ? null
          : activeClients.where((client) => client.id == _clientId).firstOrNull;
      setState(() {
        _clients = activeClients;
        _client = selectedClient;
        _services = services;
        _employees = employees.where((employee) => employee.isActive).toList();
        _businessHours = businessHours;
        _salonBreaks = salonBreaks;
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

  List<Client> _uniqueActiveClients(Iterable<Client> clients) {
    final seenIds = <String>{};
    return clients
        .where((client) => !client.isArchived && seenIds.add(client.id))
        .toList();
  }

  void _refreshSlots() {
    final appointments = DemoData.appointments;
    if (_selectedServices.isEmpty ||
        _employeeByService.length != _selectedServices.length) {
      setState(() {
        _availableSlots = [];
        _startAt = null;
      });
      return;
    }
    final drafts = _selectedServices.map((service) {
      final employeeId = _employeeByService[service.id]!;
      final employee = _employees
          .where((item) => item.id == employeeId)
          .firstOrNull;
      if (employee == null) return null;
      return AppointmentDraftService(
        service: service,
        employeeId: employee.id,
        employeeName: employee.fullName,
      );
    }).whereType<AppointmentDraftService>();
    if (drafts.length != _selectedServices.length) {
      setState(() {
        _availableSlots = [];
        _startAt = null;
        _errorMessage = 'The selected employee is no longer available.';
      });
      return;
    }
    final slots = AppointmentScheduler.availableSlots(
      date: _date,
      services: drafts,
      appointments: appointments,
      businessHours: _businessHours,
      salonBreaks: _salonBreaks,
    );
    setState(() {
      _availableSlots = slots;
      if (_startAt != null && !slots.contains(_startAt)) _startAt = null;
    });
  }

  Future<void> _createClient() async {
    final existingIds = _clients.map((client) => client.id).toSet();
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClientFormScreen(repository: widget.repository),
      ),
    );
    if (created != true || !mounted) return;
    final clients = await widget.repository.getClients();
    final newClient = clients
        .where(
          (client) => !client.isArchived && !existingIds.contains(client.id),
        )
        .firstOrNull;
    if (newClient == null) {
      setState(() {
        _errorMessage =
            'The new client could not be selected. Please try again.';
      });
      return;
    }
    setState(() {
      _clients = _uniqueActiveClients(clients);
    });
    _selectClient(newClient);
  }

  Future<void> _chooseDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      initialDate: _date,
    );
    if (selected == null) return;
    setState(() {
      _date = selected;
      _startAt = null;
    });
    _refreshSlots();
  }

  List<AppointmentService> _snapshotServices() =>
      _selectedServices.map((service) {
        final employeeId = _employeeByService[service.id]!;
        final employee = _employees.firstWhere((item) => item.id == employeeId);
        return AppointmentService(
          id: 'booking_${service.id}',
          serviceId: service.id,
          serviceName: service.name,
          category: service.category,
          durationMinutes: service.durationMinutes,
          price: service.price,
          employeeId: employee.id,
          employeeName: employee.fullName,
          historicalServiceName: service.name,
          historicalCategory: service.category,
          historicalDurationMinutes: service.durationMinutes,
          historicalPrice: service.price,
          isCapabilityOverride: _overriddenServiceIds.contains(service.id),
        );
      }).toList();

  Future<void> _confirm() async {
    if (_isSaving) return;

    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim();
    final mobileError = _mobileValidationError(mobile);
    final emailError = _emailValidationError(email);
    final client = _clientId == null
        ? null
        : _clients.where((item) => item.id == _clientId).firstOrNull;
    if (client == null ||
        _startAt == null ||
        _selectedServices.length != 1 ||
        _employeeByService.length != 1 ||
        mobileError != null ||
        emailError != null) {
      setState(() {
        _mobileError = mobileError;
        _emailError = emailError;
        _errorMessage = 'Complete all required appointment fields.';
      });
      return;
    }
    final startAt = _startAt!;
    final services = _snapshotServices();
    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _mobileError = null;
      _emailError = null;
    });
    try {
      if (mobile != (client.phone ?? '') || email != (client.email ?? '')) {
        final updatedClient = await widget.repository.updateClient(
          id: client.id,
          name: client.fullName,
          phone: mobile,
          email: email,
        );
        _client = updatedClient;
        _clients = _clients
            .map(
              (client) =>
                  client.id == updatedClient.id ? updatedClient : client,
            )
            .toList();
      }
      final reminder = _reminder == 'No reminder'
          ? null
          : Reminder(
              id: 'reminder_${DateTime.now().millisecondsSinceEpoch}',
              title: _reminder,
              message: 'Appointment reminder for ${_client!.fullName}',
              scheduledFor: startAt.subtract(
                Duration(hours: _reminder == '24 hours before' ? 24 : 2),
              ),
              isSent: false,
            );
      await widget.repository.createAppointment(
        clientId: client.id,
        clientName: client.fullName,
        startAt: startAt,
        services: services,
        reminder: reminder,
        createdBy: 'demo',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Appointment confirmed.')));
      Navigator.of(context).pop(true);
    } on RepositoryException catch (exception) {
      if (mounted) {
        setState(() {
          _errorMessage = exception.message;
          _isSaving = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Unable to create the appointment. Check the selected client, employee, and time slot.';
          _isSaving = false;
        });
      }
    }
  }

  void _next() {
    if (_step == 0 && _client == null) {
      setState(() => _errorMessage = 'Select or create a client.');
      return;
    }
    if (_step == 1 &&
        (_selectedServices.isEmpty ||
            _employeeByService.length != _selectedServices.length)) {
      setState(
        () => _errorMessage = 'Select services and assign an employee to each.',
      );
      return;
    }
    if (_step == 2 && _startAt == null) {
      setState(() => _errorMessage = 'Choose an available time.');
      return;
    }
    setState(() {
      _errorMessage = null;
      _step++;
    });
    if (_step == 2) {
      _refreshSlots();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null && _clients.isEmpty && _services.isEmpty) {
      return Scaffold(
        body: EmptyState(
          title: 'Unable to start booking',
          subtitle: _errorMessage,
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: const Text('New appointment')),
      body: SafeArea(
        child: Stepper(
          currentStep: _step,
          onStepContinue: _step == 3 ? _confirm : _next,
          onStepCancel: _step == 0
              ? null
              : () => setState(() {
                  _step--;
                  _errorMessage = null;
                }),
          controlsBuilder: (context, details) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: _step == 3 ? 'Confirm appointment' : 'Continue',
                    isLoading: _isSaving,
                    disabled: _isSaving,
                    onPressed: details.onStepContinue,
                  ),
                ),
                if (_step > 0) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          ),
          steps: [
            _clientStep(),
            _servicesStep(),
            _scheduleStep(),
            _reviewStep(),
          ],
        ),
      ),
    );
  }

  Step _clientStep() => Step(
    isActive: _step >= 0,
    title: const Text('Client'),
    content: Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _clientId,
          decoration: const InputDecoration(labelText: 'Client name'),
          items: _clients
              .map(
                (client) => DropdownMenuItem(
                  value: client.id,
                  child: Text(client.fullName),
                ),
              )
              .toList(),
          onChanged: (clientId) {
            final client = clientId == null
                ? null
                : _clients.where((item) => item.id == clientId).firstOrNull;
            _selectClient(client);
          },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _createClient,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('+ Add New Client'),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _mobileController,
          focusNode: _mobileFocusNode,
          keyboardType: TextInputType.phone,
          onChanged: (_) => _validateMobileNumber(),
          decoration: InputDecoration(
            labelText: 'Mobile number',
            errorText: _mobileError,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) {
            if (!_emailFocusNode.hasFocus) _validateContactFields();
          },
          decoration: InputDecoration(
            labelText: 'Email',
            errorText: _emailError,
          ),
        ),
      ],
    ),
  );

  Step _servicesStep() => Step(
    isActive: _step >= 1,
    title: const Text('Services and employees'),
    content: Column(
      children: [
        DropdownButtonFormField<ServiceCategory>(
          initialValue: _serviceCategory,
          decoration: const InputDecoration(labelText: 'Filter by category'),
          items: [
            const DropdownMenuItem<ServiceCategory>(
              child: Text('All categories'),
            ),
            ...ServiceCategory.values.map(
              (category) => DropdownMenuItem(
                value: category,
                child: Text(category.label),
              ),
            ),
          ],
          onChanged: (value) => setState(() => _serviceCategory = value),
        ),
        const SizedBox(height: 10),
        ..._services
            .where(
              (service) =>
                  _serviceCategory == null ||
                  service.category == _serviceCategory,
            )
            .map((service) {
              final selected = _selectedServiceIds.contains(service.id);
              final capable = _employees
                  .where((employee) => employee.serviceIds.contains(service.id))
                  .toList();
              return Column(
                key: ValueKey(service.id),
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                    onTap: () {
                      setState(() {
                        _selectedServiceIds
                          ..clear()
                          ..add(service.id);
                        _employeeByService.clear();
                        _overriddenServiceIds.clear();
                        _startAt = null;
                        _availableSlots = [];
                      });
                    },
                    title: Text(service.name),
                    subtitle: Text(
                      '${service.category.label} | ${service.durationLabel ?? '${service.durationMinutes} min'} | ${service.priceLabel ?? 'Rs ${service.price.toStringAsFixed(0)}'}',
                    ),
                  ),
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: DropdownButtonFormField<String>(
                        initialValue: _employeeByService[service.id],
                        decoration: InputDecoration(
                          labelText: 'Employee for ${service.name}',
                        ),
                        items: capable
                            .map(
                              (employee) => DropdownMenuItem(
                                value: employee.id,
                                child: Text(employee.fullName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(
                              () => _employeeByService[service.id] = value,
                            );
                          }
                        },
                        validator: (_) => capable.isEmpty
                            ? 'No capable employee assigned.'
                            : null,
                      ),
                    ),
                ],
              );
            }),
      ],
    ),
  );

  Step _scheduleStep() => Step(
    isActive: _step >= 2,
    title: const Text('Date and time'),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _chooseDate,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text('${_date.day}/${_date.month}/${_date.year}'),
        ),
        const SizedBox(height: 12),
        if (_availableSlots.isEmpty) ...[
          Text(
            'Choose a date to see available times.',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _refreshSlots,
            child: const Text('Find available times'),
          ),
        ] else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableSlots
                .map(
                  (slot) => ChoiceChip(
                    label: Text(
                      '${slot.hour.toString().padLeft(2, '0')}:${slot.minute.toString().padLeft(2, '0')}',
                    ),
                    selected: _startAt == slot,
                    onSelected: (_) => setState(() => _startAt = slot),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _reminder,
          decoration: const InputDecoration(labelText: 'Reminder'),
          items: const [
            DropdownMenuItem(value: 'No reminder', child: Text('No reminder')),
            DropdownMenuItem(
              value: '2 hours before',
              child: Text('2 hours before'),
            ),
            DropdownMenuItem(
              value: '24 hours before',
              child: Text('24 hours before'),
            ),
          ],
          onChanged: (value) =>
              setState(() => _reminder = value ?? 'No reminder'),
        ),
      ],
    ),
  );

  Step _reviewStep() => Step(
    isActive: _step >= 3,
    title: const Text('Review'),
    content: AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_client?.fullName ?? '', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          Text('Date: ${_date.day}/${_date.month}/${_date.year}'),
          Text(
            'Time: ${_startAt == null ? '-' : '${_startAt!.hour.toString().padLeft(2, '0')}:${_startAt!.minute.toString().padLeft(2, '0')}'}',
          ),
          Text('Estimated end: ${_estimatedEndLabel()}'),
          const SizedBox(height: 8),
          ..._selectedServices.map(
            (service) => Text(
              '${service.name}  |  ${service.durationLabel ?? '${service.durationMinutes} min'}  |  ${service.priceLabel ?? 'Rs ${service.price.toStringAsFixed(0)}'}  |  ${_employeeName(service.id)}',
            ),
          ),
          const SizedBox(height: 8),
          Text('Reminder: $_reminder'),
          Text(
            'Estimated total: Rs ${_selectedServices.fold<double>(0, (total, service) => total + service.price).toStringAsFixed(0)}',
          ),
        ],
      ),
    ),
  );

  String _estimatedEndLabel() {
    if (_startAt == null || _selectedServices.isEmpty) return '-';

    final drafts = <AppointmentDraftService>[];
    for (final service in _selectedServices) {
      final employeeId = _employeeByService[service.id];
      if (employeeId == null) return '-';

      Employee? employee;
      for (final candidate in _employees) {
        if (candidate.id == employeeId) {
          employee = candidate;
          break;
        }
      }
      if (employee == null) return '-';

      drafts.add(
        AppointmentDraftService(
          service: service,
          employeeId: employee.id,
          employeeName: employee.fullName,
        ),
      );
    }

    final end = AppointmentScheduler.endAt(_startAt!, drafts);
    return '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  String _employeeName(String serviceId) {
    final employeeId = _employeeByService[serviceId];
    if (employeeId == null) return 'Select employee';

    for (final employee in _employees) {
      if (employee.id == employeeId) return employee.fullName;
    }
    return 'Select employee';
  }
}
