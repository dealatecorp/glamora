import 'package:flutter/material.dart';
import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/theme/app_text_styles.dart';
import 'package:saloon_application/core/widgets/app_card.dart';
import 'package:saloon_application/core/widgets/primary_button.dart';
import 'package:saloon_application/data/repositories/repositories.dart';
import 'package:saloon_application/features/payments/domain/payment_service.dart';
import 'package:saloon_application/models/salon_models.dart';

class CustomerWebsiteScreen extends StatefulWidget {
  const CustomerWebsiteScreen({
    super.key,
    required this.repository,
    this.paymentGateway = const RazorpayPaymentGateway(),
  });

  final DemoRepository repository;
  final PaymentGateway paymentGateway;

  @override
  State<CustomerWebsiteScreen> createState() => _CustomerWebsiteScreenState();
}

class _CustomerWebsiteScreenState extends State<CustomerWebsiteScreen> {
  final _servicesKey = GlobalKey();
  final _bookingKey = GlobalKey();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();

  late Future<List<Service>> _servicesFuture;
  final Set<String> _selectedServiceIds = {};
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _servicesFuture = widget.repository.getServices();
    _nameController.addListener(_refreshSummary);
    _mobileController.addListener(_refreshSummary);
    _emailController.addListener(_refreshSummary);
  }

  @override
  void dispose() {
    _nameController.removeListener(_refreshSummary);
    _mobileController.removeListener(_refreshSummary);
    _emailController.removeListener(_refreshSummary);
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _refreshSummary() {
    if (mounted) setState(() {});
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date != null) setState(() => _preferredDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _preferredTime ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null) setState(() => _preferredTime = time);
  }

  DateTime? _selectedStartAt() {
    final date = _preferredDate;
    final time = _preferredTime;
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  List<AppointmentService>? _snapshotServices(
    List<Service> services,
    List<Employee> employees,
  ) {
    final selectedServices = services
        .where((service) => _selectedServiceIds.contains(service.id))
        .toList();
    final appointmentServices = <AppointmentService>[];
    for (final service in selectedServices) {
      final capableEmployees = employees.where(
        (employee) =>
            employee.isActive && employee.serviceIds.contains(service.id),
      );
      final employee = capableEmployees.firstOrNull;
      if (employee == null) return null;
      appointmentServices.add(
        AppointmentService(
          id: 'customer_${service.id}',
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
        ),
      );
    }
    return appointmentServices;
  }

  Future<Client> _upsertClient() async {
    final name = _nameController.text.trim();
    final phone = _mobileController.text.trim();
    final email = _emailController.text.trim();
    final clients = await widget.repository.getClients();
    final existing = clients
        .where((client) => !client.isArchived && client.phone == phone)
        .firstOrNull;
    if (existing == null) {
      return widget.repository.createClient(
        name: name,
        phone: phone,
        email: email,
      );
    }
    if (existing.fullName != name || (existing.email ?? '') != email) {
      return widget.repository.updateClient(
        id: existing.id,
        name: name,
        phone: phone,
        email: email,
      );
    }
    return existing;
  }

  Future<void> _confirm(List<Service> services) async {
    if (_isSaving) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    final startAt = _selectedStartAt();
    if (!isValid || _selectedServiceIds.isEmpty || startAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete customer, service, date, and time details.'),
        ),
      );
      return;
    }
    if (!startAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future appointment time.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final employees = await widget.repository.getEmployees();
      final appointmentServices = _snapshotServices(services, employees);
      if (appointmentServices == null || appointmentServices.isEmpty) {
        throw const RepositoryException(
          'No available employee is assigned to one or more selected services.',
        );
      }
      final bookingReference =
          'customer_booking_${DateTime.now().millisecondsSinceEpoch}';
      final pendingAppointment = Appointment(
        id: bookingReference,
        clientId: 'pending_${_mobileController.text.trim()}',
        clientName: _nameController.text.trim(),
        employeeId: appointmentServices.first.employeeId,
        employeeName: appointmentServices.first.employeeName,
        startAt: startAt,
        endAt: startAt.add(
          Duration(
            minutes: appointmentServices.fold(
              0,
              (total, service) => total + service.durationMinutes,
            ),
          ),
        ),
        status: AppointmentStatus.confirmed,
        services: List.unmodifiable(appointmentServices),
        source: 'customer_website',
        createdAt: DateTime.now(),
        createdBy: 'customer_website',
      );
      final paymentRequest = await widget.paymentGateway.createPaymentRequest(
        invoice: Invoice(
          id: 'customer_invoice_${pendingAppointment.id}',
          appointmentId: pendingAppointment.id,
          clientId: pendingAppointment.clientId,
          clientName: pendingAppointment.clientName,
          subtotal: pendingAppointment.totalPrice,
          tax: 0,
          total: pendingAppointment.totalPrice,
          issuedAt: DateTime.now(),
          isPaid: false,
          paymentStatus: PaymentStatus.pending,
          amountPaid: 0,
          balance: pendingAppointment.totalPrice,
        ),
        method: PaymentMethod.razorpay,
      );
      final transactionId = await widget.paymentGateway.verifyPayment(
        request: paymentRequest,
        transactionReference: paymentRequest.reference,
      );
      final client = await _upsertClient();
      final appointment = await widget.repository.createAppointment(
        clientId: client.id,
        clientName: client.fullName,
        startAt: startAt,
        services: appointmentServices,
        createdBy: 'customer_website',
      );
      final payment = await widget.repository.createAppointmentPaymentRecord(
        appointment: appointment,
        amount: appointment.totalPrice,
        method: PaymentMethod.razorpay,
      );
      await widget.repository.verifyPaymentRecord(
        paymentId: payment.id,
        transactionId: transactionId,
      );
      if (!mounted) return;
      setState(() {
        _selectedServiceIds.clear();
        _preferredDate = null;
        _preferredTime = null;
        _isSaving = false;
      });
      _formKey.currentState?.reset();
      _nameController.clear();
      _mobileController.clear();
      _emailController.clear();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Booking confirmed'),
          content: Text(
            'Your Glamora appointment is confirmed for ${_formatDate(appointment.startAt)} at ${_formatTime(context, appointment.startAt)}.\nPayment status: Paid',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on RepositoryException catch (exception) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    } on PaymentException catch (exception) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save the booking. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.warmIvory,
    body: SafeArea(
      child: FutureBuilder<List<Service>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load services.'));
          }
          final loadedServices = snapshot.data ?? const <Service>[];
          final services = List<Service>.of(loadedServices)
            ..sort((a, b) {
              final categoryOrder = a.category.index.compareTo(
                b.category.index,
              );
              if (categoryOrder != 0) return categoryOrder;
              final durationOrder = a.durationMinutes.compareTo(
                b.durationMinutes,
              );
              if (durationOrder != 0) return durationOrder;
              return a.name.compareTo(b.name);
            });
          final selectedServices = services
              .where((service) => _selectedServiceIds.contains(service.id))
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              _HeroSection(
                onBook: () => _scrollTo(_bookingKey),
                onServices: () => _scrollTo(_servicesKey),
              ),
              const SizedBox(height: 18),
              _ServiceOverview(services: services),
              const SizedBox(height: 18),
              _ServicesSection(
                key: _servicesKey,
                services: services,
                selectedServiceIds: _selectedServiceIds,
                onChanged: (service, selected) {
                  setState(() {
                    if (selected) {
                      _selectedServiceIds.add(service.id);
                    } else {
                      _selectedServiceIds.remove(service.id);
                    }
                  });
                },
              ),
              const SizedBox(height: 18),
              _BookingSection(
                key: _bookingKey,
                formKey: _formKey,
                nameController: _nameController,
                mobileController: _mobileController,
                emailController: _emailController,
                preferredDate: _preferredDate,
                preferredTime: _preferredTime,
                onPickDate: _pickDate,
                onPickTime: _pickTime,
              ),
              const SizedBox(height: 18),
              _SummarySection(
                name: _nameController.text.trim(),
                mobile: _mobileController.text.trim(),
                email: _emailController.text.trim(),
                services: selectedServices,
                preferredDate: _preferredDate,
                preferredTime: _preferredTime,
                isSaving: _isSaving,
                onConfirm: () => _confirm(services),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onBook, required this.onServices});

  final VoidCallback onBook;
  final VoidCallback onServices;

  @override
  Widget build(BuildContext context) => AppCard(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        final textContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.spa_rounded, color: AppColors.champagneGold),
                const SizedBox(width: 8),
                Text('Glamora', style: AppTextStyles.titleLarge),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Book your salon visit in advance',
              style: AppTextStyles.displayLarge,
            ),
            const SizedBox(height: 10),
            Text(
              'Explore Glamora services, choose your preferred treatments, and prepare your appointment request before reaching the salon.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                PrimaryButton(
                  label: 'Book Appointment',
                  icon: Icons.calendar_month_rounded,
                  onPressed: onBook,
                ),
                OutlinedButton.icon(
                  onPressed: onServices,
                  icon: const Icon(Icons.room_service_rounded),
                  label: const Text('View Services'),
                ),
              ],
            ),
          ],
        );
        final iconPanel = Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.person_add_alt_1_rounded,
            size: 88,
            color: AppColors.champagneGold,
          ),
        );
        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              textContent,
              const SizedBox(height: 18),
              iconPanel,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: textContent,
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: iconPanel,
            ),
          ],
        );
      },
    ),
  );
}

class _ServiceOverview extends StatelessWidget {
  const _ServiceOverview({required this.services});

  final List<Service> services;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: ServiceCategory.values
          .map(
            (category) => Chip(
              avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
              label: Text(
                '${category.label} (${services.where((service) => service.category == category).length})',
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({
    super.key,
    required this.services,
    required this.selectedServiceIds,
    required this.onChanged,
  });

  final List<Service> services;
  final Set<String> selectedServiceIds;
  final void Function(Service service, bool selected) onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Services', style: AppTextStyles.displaySmall),
      const SizedBox(height: 10),
      for (final category in ServiceCategory.values) ...[
        AppCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category.label, style: AppTextStyles.titleLarge),
              const SizedBox(height: 10),
              ...services
                  .where((service) => service.category == category)
                  .map(
                    (service) {
                      final duration =
                          service.durationLabel ??
                          _formatDuration(service.durationMinutes);
                      final price =
                          service.priceLabel ??
                          'Rs ${service.price.toStringAsFixed(0)}';
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: selectedServiceIds.contains(service.id),
                        onChanged: (value) =>
                            onChanged(service, value ?? false),
                        title: Text(
                          service.name,
                          style: AppTextStyles.titleMedium,
                        ),
                        subtitle: Text(
                          '$duration | $price',
                          style: AppTextStyles.bodySmall,
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
            ],
          ),
        ),
      ],
    ],
  );
}

class _BookingSection extends StatelessWidget {
  const _BookingSection({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.mobileController,
    required this.emailController,
    required this.preferredDate,
    required this.preferredTime,
    required this.onPickDate,
    required this.onPickTime,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController mobileController;
  final TextEditingController emailController;
  final DateTime? preferredDate;
  final TimeOfDay? preferredTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Book Appointment', style: AppTextStyles.displaySmall),
          const SizedBox(height: 14),
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Customer name'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Customer name is required.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: mobileController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile number'),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Mobile number is required.'
                : RegExp(r'^\d{10}$').hasMatch(value.trim())
                ? null
                : 'Mobile number must be exactly 10 digits.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'Email is required.';
              if (!text.contains('@')) return 'Enter a valid email.';
              return null;
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.event_rounded),
                label: Text(
                  preferredDate == null
                      ? 'Preferred date'
                      : _formatDate(preferredDate!),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onPickTime,
                icon: const Icon(Icons.schedule_rounded),
                label: Text(
                  preferredTime == null
                      ? 'Preferred time'
                      : preferredTime!.format(context),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({
    required this.name,
    required this.mobile,
    required this.email,
    required this.services,
    required this.preferredDate,
    required this.preferredTime,
    required this.isSaving,
    required this.onConfirm,
  });

  final String name;
  final String mobile;
  final String email;
  final List<Service> services;
  final DateTime? preferredDate;
  final TimeOfDay? preferredTime;
  final bool isSaving;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final totalDuration = services.fold<int>(
      0,
      (total, service) => total + service.durationMinutes,
    );
    final totalAmount = services.fold<double>(
      0,
      (total, service) => total + service.price,
    );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking Summary', style: AppTextStyles.displaySmall),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Customer',
            value: name.isEmpty ? 'Not provided' : name,
          ),
          _SummaryRow(
            label: 'Mobile',
            value: mobile.isEmpty ? 'Not provided' : mobile,
          ),
          _SummaryRow(
            label: 'Email',
            value: email.isEmpty ? 'Not provided' : email,
          ),
          _SummaryRow(
            label: 'Services',
            value: services.isEmpty
                ? 'No services selected'
                : services.map((service) => service.name).join(', '),
          ),
          _SummaryRow(
            label: 'Total duration',
            value: _formatDuration(totalDuration),
          ),
          _SummaryRow(
            label: 'Total amount',
            value: 'Rs ${totalAmount.toStringAsFixed(0)}',
          ),
          _SummaryRow(
            label: 'Date/time',
            value: preferredDate == null || preferredTime == null
                ? 'Not selected'
                : '${_formatDate(preferredDate!)} at ${preferredTime!.format(context)}',
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Confirm Booking',
            icon: Icons.check_circle_rounded,
            isLoading: isSaving,
            disabled: isSaving,
            onPressed: onConfirm,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: Text(label, style: AppTextStyles.bodySmall),
        ),
        Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
      ],
    ),
  );
}

String _formatDuration(int minutes) {
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (hours == 0) return '$remaining min';
  if (remaining == 0) return '$hours hr';
  return '$hours hr $remaining min';
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String _formatTime(BuildContext context, DateTime date) =>
    TimeOfDay.fromDateTime(date).format(context);
