import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:saloon_application/models/salon_models.dart';
import 'package:saloon_application/features/appointments/domain/appointment_scheduler.dart';
import 'package:saloon_application/features/billing/domain/billing_calculator.dart';

abstract class ClientRepository {
  Future<List<Client>> getClients();

  Future<Client?> getClientById(String id);

  Future<List<Client>> searchClients(String query);

  Future<Client> createClient({
    required String name,
    required String phone,
    String? email,
  });

  Future<Client> updateClient({
    required String id,
    required String name,
    required String phone,
    String? email,
  });

  Future<void> archiveClient(String id);

  Future<void> restoreClient(String id);

  Future<void> deleteClient(String id);

  Future<ClientHistory> getClientHistory(String clientId);

  Future<Client> updateLoyaltyXp(String id, int delta);
}

abstract class ServiceRepository {
  Future<List<Service>> getServices({bool includeArchived = false});

  Future<Service?> getServiceById(String id);

  Future<List<Service>> searchServices(String query);

  Future<List<Service>> getServicesByCategory(
    ServiceCategory category, {
    bool includeArchived = false,
  });

  Future<Service> createService({
    required String name,
    required ServiceCategory category,
    required int durationMinutes,
    required double price,
    required String description,
    required List<String> assignedEmployeeIds,
  });

  Future<Service> updateService({
    required String id,
    required String name,
    required ServiceCategory category,
    required int durationMinutes,
    required double price,
    required String description,
    required List<String> assignedEmployeeIds,
  });

  Future<void> archiveService(String id);

  Future<void> restoreService(String id);
}

abstract class AppointmentRepository {
  Future<List<Appointment>> getAppointments();

  Future<Appointment?> getAppointmentById(String id);

  Future<AvailabilityResult> checkAvailability({
    required DateTime startAt,
    required List<AppointmentService> services,
    String? excludingAppointmentId,
  });

  Future<Appointment> createAppointment({
    required String clientId,
    required String clientName,
    required DateTime startAt,
    required List<AppointmentService> services,
    Reminder? reminder,
    String? createdBy,
  });

  Future<Appointment> updateAppointment(Appointment appointment);

  Future<Appointment> cancelAppointment({
    required String id,
    required String reason,
    required String cancelledBy,
  });

  Future<Appointment> markNoShow(String id);

  Future<Appointment> completeAppointment(String id);
}

abstract class EmployeeRepository {
  Future<List<Employee>> getEmployees({bool includeArchived = false});

  Future<Employee?> getEmployeeById(String id);

  Future<List<Employee>> searchEmployees(
    String query, {
    bool includeArchived = false,
  });

  Future<Employee> createEmployee({
    required String id,
    required String name,
    required String phone,
    required String pin,
    required List<String> serviceIds,
    String? email,
    int experienceYears = 0,
  });

  Future<Employee> updateEmployee({
    required String id,
    required String name,
    required String phone,
    required List<String> serviceIds,
    String? email,
    int experienceYears = 0,
  });

  Future<void> archiveEmployee(String id);

  Future<void> restoreEmployee(String id);

  Future<void> resetEmployeePin(String id, String newPin);

  Future<List<Appointment>> getEmployeeAppointments(String employeeId);

  Future<List<EmployeeRewardTransaction>> getEmployeeRewardHistory(
    String employeeId,
  );

  Future<Employee> adjustEmployeeXp({
    required String employeeId,
    required int amount,
    required String reason,
    required String performedBy,
  });
}

abstract class PaymentRepository {
  Future<List<Payment>> getPayments();

  Future<Payment?> getPaymentByInvoiceId(String invoiceId);

  Future<Payment> createPaymentRecord({
    required Invoice invoice,
    required PaymentMethod method,
  });

  Future<Payment> createAppointmentPaymentRecord({
    required Appointment appointment,
    required double amount,
    required PaymentMethod method,
  });

  Future<Payment> verifyPaymentRecord({
    required String paymentId,
    required String transactionId,
  });

  Future<Payment> failPayment({required String paymentId, String? reason});

  Future<Payment> refundPayment({
    required String paymentId,
    required String refundReference,
  });
}

abstract class InvoiceRepository {
  Future<List<Invoice>> getInvoices();

  Future<Invoice?> getInvoiceById(String id);

  Future<Invoice?> getInvoiceByAppointmentId(String appointmentId);

  Future<BillingQuote> calculateInvoice({
    required String appointmentId,
    required DiscountType discountType,
    required double discountValue,
  });

  Future<Invoice> createInvoice({
    required String appointmentId,
    required DiscountType discountType,
    required double discountValue,
  });
}

abstract class InventoryRepository {
  Future<List<InventoryProduct>> getProducts({bool includeArchived = false});
  Future<InventoryProduct?> getProductById(String id);
  Future<List<InventoryTransaction>> getInventoryTransactions(String productId);
  Future<InventoryProduct> createProduct({
    required String name,
    required String category,
    required double cost,
    required int quantity,
    required int lowStockThreshold,
    required String performedBy,
  });
  Future<InventoryProduct> updateProduct({
    required String id,
    required String name,
    required String category,
    required double cost,
    required int lowStockThreshold,
    int? quantity,
    String? adjustmentReason,
    required String performedBy,
  });
  Future<InventoryProduct> changeStock({
    required String productId,
    required InventoryTransactionType type,
    required int quantity,
    required String reason,
    required String performedBy,
  });
  Future<void> archiveProduct(String id);
  Future<void> restoreProduct(String id);
}

abstract class SettingsRepository {
  Future<BusinessProfile> getBusinessProfile();
  Future<List<BusinessHours>> getBusinessHours();
  Future<List<SalonBreak>> getSalonBreaks();
  Future<ApplicationSettings> getApplicationSettings();
  Future<BusinessProfile> updateBusinessProfile(BusinessProfile profile);
  Future<List<BusinessHours>> updateBusinessHours(List<BusinessHours> hours);
  Future<List<SalonBreak>> updateSalonBreaks(List<SalonBreak> breaks);
  Future<ApplicationSettings> updateApplicationSettings(
    ApplicationSettings settings,
  );
}

class DemoRepository
    implements
        ClientRepository,
        ServiceRepository,
        AppointmentRepository,
        EmployeeRepository,
        PaymentRepository,
        InvoiceRepository,
        InventoryRepository,
        SettingsRepository {
  static const _persistedClientsKey = 'glamora.demo_clients';
  static const _persistedAppointmentsKey = 'glamora.demo_appointments';
  static const _persistedBusinessProfileKey = 'glamora.demo_business_profile';
  static const _persistedBusinessHoursKey = 'glamora.demo_business_hours';
  static const _persistedSalonBreaksKey = 'glamora.demo_salon_breaks';
  static const _persistedApplicationSettingsKey =
      'glamora.demo_application_settings';
  Future<void>? _clientPersistenceLoad;
  Future<void>? _appointmentPersistenceLoad;
  Future<void>? _settingsPersistenceLoad;

  Future<void> _ensurePersistedClientsLoaded() =>
      _clientPersistenceLoad ??= _loadPersistedClients();

  Future<void> _ensurePersistedAppointmentsLoaded() =>
      _appointmentPersistenceLoad ??= _loadPersistedAppointments();

  Future<void> _ensurePersistedSettingsLoaded() =>
      _settingsPersistenceLoad ??= _loadPersistedSettings();

  Future<void> _loadPersistedClients() async {
    try {
      final preferences = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 250),
      );
      final encoded = preferences.getString(_persistedClientsKey);
      if (encoded == null || encoded.isEmpty) return;
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return;

      final existingIds = DemoData.clients.map((client) => client.id).toSet();
      for (final value in decoded) {
        if (value is! Map<String, dynamic>) continue;
        final client = _clientFromJson(value);
        if (client != null && existingIds.add(client.id)) {
          DemoData.clients.add(client);
        }
      }
    } catch (_) {
      // The in-memory demo data remains usable when local storage is unavailable.
    }
  }

  Future<void> _persistUserClients() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final seedIds = DemoData.seedClientIds;
      final userClients = DemoData.clients
          .where((client) => !seedIds.contains(client.id))
          .map(_clientToJson)
          .toList();
      await preferences.setString(
        _persistedClientsKey,
        jsonEncode(userClients),
      );
    } catch (_) {
      // Keep the local demo flow working if persistence is temporarily unavailable.
    }
  }

  Future<void> _loadPersistedAppointments() async {
    try {
      final preferences = await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 250),
      );
      final encoded = preferences.getString(_persistedAppointmentsKey);
      if (encoded == null || encoded.isEmpty) return;
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return;

      for (final value in decoded) {
        if (value is! Map<String, dynamic>) continue;
        final appointment = _appointmentFromJson(value);
        if (appointment == null) continue;
        final index = DemoData.appointments.indexWhere(
          (item) => item.id == appointment.id,
        );
        if (index < 0) {
          DemoData.appointments.add(appointment);
        } else {
          DemoData.appointments[index] = appointment;
        }
      }
    } catch (_) {
      // The in-memory demo appointments remain usable when storage is unavailable.
    }
  }

  Future<void> _persistAppointments() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _persistedAppointmentsKey,
        jsonEncode(DemoData.appointments.map(_appointmentToJson).toList()),
      );
    } catch (_) {
      // Keep the local demo flow working if persistence is temporarily unavailable.
    }
  }

  Map<String, dynamic> _appointmentToJson(Appointment appointment) => {
    'id': appointment.id,
    'clientId': appointment.clientId,
    'clientName': appointment.clientName,
    'employeeId': appointment.employeeId,
    'employeeName': appointment.employeeName,
    'startAt': appointment.startAt.toIso8601String(),
    'endAt': appointment.endAt.toIso8601String(),
    'status': appointment.status.name,
    'paymentStatus': appointment.paymentStatus.name,
    'services': appointment.services.map(_appointmentServiceToJson).toList(),
    'notes': appointment.notes,
    'source': appointment.source,
    'createdAt': appointment.createdAt.toIso8601String(),
    'updatedAt': appointment.updatedAt.toIso8601String(),
    'createdBy': appointment.createdBy,
    'reminder': appointment.reminder == null
        ? null
        : _reminderToJson(appointment.reminder!),
    'cancellationReason': appointment.cancellationReason,
    'cancelledBy': appointment.cancelledBy,
    'cancelledAt': appointment.cancelledAt?.toIso8601String(),
  };

  Appointment? _appointmentFromJson(Map<String, dynamic> value) {
    final startAt = DateTime.tryParse(value['startAt'] as String? ?? '');
    final endAt = DateTime.tryParse(value['endAt'] as String? ?? '');
    final createdAt = DateTime.tryParse(value['createdAt'] as String? ?? '');
    if (startAt == null || endAt == null || createdAt == null) return null;
    final servicesValue = value['services'];
    if (servicesValue is! List) return null;
    final services = servicesValue
        .whereType<Map<String, dynamic>>()
        .map(_appointmentServiceFromJson)
        .whereType<AppointmentService>()
        .toList();
    if (services.isEmpty) return null;
    final status = _appointmentStatusFromJson(value['status'] as String?);
    final paymentStatus = _paymentStatusFromJson(
      value['paymentStatus'] as String?,
    );
    if (status == null || paymentStatus == null) return null;
    return Appointment(
      id: value['id'] as String? ?? '',
      clientId: value['clientId'] as String? ?? '',
      clientName: value['clientName'] as String? ?? '',
      employeeId: value['employeeId'] as String?,
      employeeName: value['employeeName'] as String?,
      startAt: startAt,
      endAt: endAt,
      status: status,
      paymentStatus: paymentStatus,
      services: List.unmodifiable(services),
      notes: value['notes'] as String?,
      source: value['source'] as String?,
      createdAt: createdAt,
      updatedAt: DateTime.tryParse(value['updatedAt'] as String? ?? ''),
      createdBy: value['createdBy'] as String?,
      reminder: _reminderFromJson(value['reminder']),
      cancellationReason: value['cancellationReason'] as String?,
      cancelledBy: value['cancelledBy'] as String?,
      cancelledAt: DateTime.tryParse(value['cancelledAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> _appointmentServiceToJson(AppointmentService service) =>
      {
        'id': service.id,
        'serviceId': service.serviceId,
        'serviceName': service.serviceName,
        'category': service.category?.name,
        'durationMinutes': service.durationMinutes,
        'price': service.price,
        'employeeId': service.employeeId,
        'employeeName': service.employeeName,
        'historicalServiceName': service.historicalServiceName,
        'historicalCategory': service.historicalCategory?.name,
        'historicalDurationMinutes': service.historicalDurationMinutes,
        'historicalPrice': service.historicalPrice,
        'isCapabilityOverride': service.isCapabilityOverride,
      };

  AppointmentService? _appointmentServiceFromJson(Map<String, dynamic> value) {
    final duration = value['durationMinutes'];
    final price = value['price'];
    if (duration is! int || price is! num) return null;
    return AppointmentService(
      id: value['id'] as String? ?? '',
      serviceId: value['serviceId'] as String? ?? '',
      serviceName: value['serviceName'] as String? ?? '',
      category: _serviceCategoryFromJson(value['category'] as String?),
      durationMinutes: duration,
      price: price.toDouble(),
      employeeId: value['employeeId'] as String?,
      employeeName: value['employeeName'] as String?,
      historicalServiceName: value['historicalServiceName'] as String?,
      historicalCategory: _serviceCategoryFromJson(
        value['historicalCategory'] as String?,
      ),
      historicalDurationMinutes: value['historicalDurationMinutes'] as int?,
      historicalPrice: (value['historicalPrice'] as num?)?.toDouble(),
      isCapabilityOverride: value['isCapabilityOverride'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _reminderToJson(Reminder reminder) => {
    'id': reminder.id,
    'title': reminder.title,
    'message': reminder.message,
    'scheduledFor': reminder.scheduledFor.toIso8601String(),
    'isSent': reminder.isSent,
  };

  Reminder? _reminderFromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final scheduledFor = DateTime.tryParse(
      value['scheduledFor'] as String? ?? '',
    );
    if (scheduledFor == null) return null;
    return Reminder(
      id: value['id'] as String? ?? '',
      title: value['title'] as String? ?? '',
      message: value['message'] as String? ?? '',
      scheduledFor: scheduledFor,
      isSent: value['isSent'] as bool? ?? false,
    );
  }

  AppointmentStatus? _appointmentStatusFromJson(String? value) {
    for (final status in AppointmentStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }

  PaymentStatus? _paymentStatusFromJson(String? value) {
    for (final status in PaymentStatus.values) {
      if (status.name == value) return status;
    }
    return null;
  }

  ServiceCategory? _serviceCategoryFromJson(String? value) {
    for (final category in ServiceCategory.values) {
      if (category.name == value) return category;
    }
    return null;
  }

  Future<void> _loadPersistedSettings() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final profileJson = preferences.getString(_persistedBusinessProfileKey);
      if (profileJson != null) {
        final decoded = jsonDecode(profileJson);
        if (decoded is Map<String, dynamic>) {
          final profile = _businessProfileFromJson(decoded);
          if (profile != null) DemoData.businessProfile = profile;
        }
      }

      final hoursJson = preferences.getString(_persistedBusinessHoursKey);
      if (hoursJson != null) {
        final decoded = jsonDecode(hoursJson);
        if (decoded is List) {
          final hours = decoded
              .whereType<Map<String, dynamic>>()
              .map(_businessHoursFromJson)
              .whereType<BusinessHours>()
              .toList();
          if (hours.isNotEmpty) DemoData.businessHours = hours;
        }
      }

      final breaksJson = preferences.getString(_persistedSalonBreaksKey);
      if (breaksJson != null) {
        final decoded = jsonDecode(breaksJson);
        if (decoded is List) {
          DemoData.salonBreaks = decoded
              .whereType<Map<String, dynamic>>()
              .map(_salonBreakFromJson)
              .whereType<SalonBreak>()
              .toList();
        }
      }

      final settingsJson = preferences.getString(
        _persistedApplicationSettingsKey,
      );
      if (settingsJson != null) {
        final decoded = jsonDecode(settingsJson);
        if (decoded is Map<String, dynamic>) {
          final settings = _applicationSettingsFromJson(decoded);
          if (settings != null) DemoData.applicationSettings = settings;
        }
      }
    } catch (_) {
      // In-memory demo settings remain usable when local storage is unavailable.
    }
  }

  Future<void> _persistSettings() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await Future.wait([
        preferences.setString(
          _persistedBusinessProfileKey,
          jsonEncode(_businessProfileToJson(DemoData.businessProfile)),
        ),
        preferences.setString(
          _persistedBusinessHoursKey,
          jsonEncode(DemoData.businessHours.map(_businessHoursToJson).toList()),
        ),
        preferences.setString(
          _persistedSalonBreaksKey,
          jsonEncode(DemoData.salonBreaks.map(_salonBreakToJson).toList()),
        ),
        preferences.setString(
          _persistedApplicationSettingsKey,
          jsonEncode(_applicationSettingsToJson(DemoData.applicationSettings)),
        ),
      ]);
    } catch (_) {
      throw const RepositoryException(
        'Unable to save studio settings. Please try again.',
      );
    }
  }

  Map<String, dynamic> _businessProfileToJson(BusinessProfile profile) => {
    'id': profile.id,
    'salonName': profile.salonName,
    'tagline': profile.tagline,
    'address': profile.address,
    'phone': profile.phone,
    'email': profile.email,
    'logoUrl': profile.logoUrl,
    'createdAt': profile.createdAt.toIso8601String(),
    'currency': profile.currency,
  };

  BusinessProfile? _businessProfileFromJson(Map<String, dynamic> value) {
    final createdAt = DateTime.tryParse(value['createdAt'] as String? ?? '');
    if (createdAt == null) return null;
    return BusinessProfile(
      id: value['id'] as String? ?? 'bp_01',
      salonName: value['salonName'] as String? ?? '',
      tagline: value['tagline'] as String? ?? '',
      address: value['address'] as String? ?? '',
      phone: value['phone'] as String? ?? '',
      email: value['email'] as String? ?? '',
      logoUrl: value['logoUrl'] as String?,
      createdAt: createdAt,
      currency: value['currency'] as String? ?? 'INR',
    );
  }

  Map<String, dynamic> _businessHoursToJson(BusinessHours hours) => {
    'id': hours.id,
    'dayName': hours.dayName,
    'openTime': hours.openTime,
    'closeTime': hours.closeTime,
    'isClosed': hours.isClosed,
  };

  BusinessHours? _businessHoursFromJson(Map<String, dynamic> value) {
    final dayName = value['dayName'] as String?;
    if (dayName == null || dayName.isEmpty) return null;
    return BusinessHours(
      id: value['id'] as String? ?? 'hours_$dayName',
      dayName: dayName,
      openTime: value['openTime'] as String? ?? '09:00',
      closeTime: value['closeTime'] as String? ?? '18:00',
      isClosed: value['isClosed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _salonBreakToJson(SalonBreak item) => {
    'id': item.id,
    'title': item.title,
    'startTime': item.startTime,
    'endTime': item.endTime,
    'date': item.date.toIso8601String(),
  };

  SalonBreak? _salonBreakFromJson(Map<String, dynamic> value) {
    final date = DateTime.tryParse(value['date'] as String? ?? '');
    if (date == null) return null;
    return SalonBreak(
      id: value['id'] as String? ?? 'break_demo',
      title: value['title'] as String? ?? 'Salon break',
      startTime: value['startTime'] as String? ?? '13:00',
      endTime: value['endTime'] as String? ?? '14:00',
      date: date,
    );
  }

  Map<String, dynamic> _applicationSettingsToJson(
    ApplicationSettings settings,
  ) => {
    'defaultAppointmentDuration': settings.defaultAppointmentDuration,
    'reminderHours': settings.reminderHours,
    'notificationsEnabled': settings.notificationsEnabled,
    'customerBookingUrl': settings.customerBookingUrl,
  };

  ApplicationSettings? _applicationSettingsFromJson(
    Map<String, dynamic> value,
  ) {
    final duration = value['defaultAppointmentDuration'];
    final reminderHours = value['reminderHours'];
    if (duration is! int || reminderHours is! int) return null;
    return ApplicationSettings(
      defaultAppointmentDuration: duration,
      reminderHours: reminderHours,
      notificationsEnabled: value['notificationsEnabled'] as bool? ?? true,
      customerBookingUrl:
          value['customerBookingUrl'] as String? ??
          'https://glamora.example.com/book',
    );
  }

  Map<String, dynamic> _clientToJson(Client client) => {
    'id': client.id,
    'fullName': client.fullName,
    'phone': client.phone,
    'email': client.email,
    'notes': client.notes,
    'createdAt': client.createdAt.toIso8601String(),
    'lastVisitAt': client.lastVisitAt?.toIso8601String(),
    'loyaltyPoints': client.loyaltyPoints,
    'visitCount': client.visitCount,
    'isVip': client.isVip,
    'isArchived': client.isArchived,
    'updatedAt': client.updatedAt.toIso8601String(),
  };

  Client? _clientFromJson(Map<String, dynamic> value) {
    final id = value['id'];
    final name = value['fullName'];
    final createdAt = DateTime.tryParse('${value['createdAt'] ?? ''}');
    final updatedAt = DateTime.tryParse('${value['updatedAt'] ?? ''}');
    if (id is! String || name is! String || createdAt == null) return null;
    return Client(
      id: id,
      fullName: name,
      phone: value['phone'] as String?,
      email: value['email'] as String?,
      notes: value['notes'] as String?,
      createdAt: createdAt,
      lastVisitAt: DateTime.tryParse('${value['lastVisitAt'] ?? ''}'),
      loyaltyPoints: value['loyaltyPoints'] as int? ?? 0,
      visitCount: value['visitCount'] as int? ?? 0,
      isVip: value['isVip'] as bool? ?? false,
      isArchived: value['isArchived'] as bool? ?? false,
      updatedAt: updatedAt,
    );
  }

  @override
  Future<List<Client>> getClients() async {
    await _ensurePersistedClientsLoaded();
    return List.unmodifiable(DemoData.clients);
  }

  @override
  Future<Client?> getClientById(String id) async {
    await _ensurePersistedClientsLoaded();
    for (final client in DemoData.clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  @override
  Future<List<Client>> searchClients(String query) async {
    await _ensurePersistedClientsLoaded();
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return getClients();
    final histories = <String, ClientHistory>{};
    for (final client in DemoData.clients) {
      histories[client.id] = await getClientHistory(client.id);
    }
    return DemoData.clients.where((client) {
      final history = histories[client.id]!;
      final searchable = [
        client.fullName,
        client.phone ?? '',
        client.email ?? '',
        ...history.appointments
            .expand((appointment) => appointment.services)
            .expand(
              (service) => [
                service.historicalServiceName ?? service.serviceName,
                service.price.toString(),
              ],
            ),
        ...history.appointments.map(
          (appointment) => appointment.startAt.toIso8601String(),
        ),
        ...history.payments.map((payment) => payment.status.name),
      ].join(' ').toLowerCase();
      return searchable.contains(normalizedQuery);
    }).toList();
  }

  @override
  Future<Client> createClient({
    required String name,
    required String phone,
    String? email,
  }) async {
    await _ensurePersistedClientsLoaded();
    _ensureUniquePhone(phone);
    final now = DateTime.now();
    final client = Client(
      id: 'client_${DemoData.clients.length + 1}',
      fullName: name.trim(),
      phone: phone.trim(),
      email: email?.trim().isEmpty == true ? null : email?.trim(),
      createdAt: now,
      updatedAt: now,
    );
    DemoData.clients.add(client);
    await _persistUserClients();
    return client;
  }

  @override
  Future<Client> updateClient({
    required String id,
    required String name,
    required String phone,
    String? email,
  }) async {
    await _ensurePersistedClientsLoaded();
    _ensureUniquePhone(phone, excludingId: id);
    final index = DemoData.clients.indexWhere((client) => client.id == id);
    if (index < 0) {
      throw const RepositoryException('Client was not found.');
    }
    final updated = DemoData.clients[index].copyWith(
      fullName: name.trim(),
      phone: phone.trim(),
      email: email?.trim().isEmpty == true ? null : email?.trim(),
    );
    DemoData.clients[index] = updated;
    await _persistUserClients();
    return updated;
  }

  @override
  Future<void> archiveClient(String id) async {
    await _ensurePersistedClientsLoaded();
    await _setArchived(id, true);
    await _persistUserClients();
  }

  @override
  Future<void> restoreClient(String id) async {
    await _ensurePersistedClientsLoaded();
    await _setArchived(id, false);
    await _persistUserClients();
  }

  @override
  Future<void> deleteClient(String id) async {
    await _ensurePersistedClientsLoaded();
    final index = DemoData.clients.indexWhere((client) => client.id == id);
    if (index < 0) {
      throw const RepositoryException('Client was not found.');
    }
    DemoData.clients.removeAt(index);
    await _persistUserClients();
  }

  @override
  Future<ClientHistory> getClientHistory(String clientId) async {
    await _ensurePersistedAppointmentsLoaded();
    return ClientHistory(
      appointments: DemoData.appointments
          .where((appointment) => appointment.clientId == clientId)
          .toList(),
      payments: DemoData.payments
          .where((payment) => payment.clientId == clientId)
          .toList(),
      invoices: DemoData.invoices
          .where((invoice) => invoice.clientId == clientId)
          .toList(),
    );
  }

  @override
  Future<Client> updateLoyaltyXp(String id, int delta) async {
    await _ensurePersistedClientsLoaded();
    final client = await getClientById(id);
    if (client == null) {
      throw const RepositoryException('Client was not found.');
    }
    final nextBalance = client.loyaltyPoints + delta;
    if (nextBalance < 0) {
      throw const RepositoryException('Loyalty XP cannot be negative.');
    }
    final index = DemoData.clients.indexWhere((item) => item.id == id);
    final updated = client.copyWith(loyaltyPoints: nextBalance);
    DemoData.clients[index] = updated;
    await _persistUserClients();
    return updated;
  }

  void _ensureUniquePhone(String phone, {String? excludingId}) {
    final normalized = phone.trim();
    final duplicate = DemoData.clients.any(
      (client) =>
          !client.isArchived &&
          client.id != excludingId &&
          client.phone?.trim() == normalized,
    );
    if (duplicate) {
      throw const RepositoryException(
        'A client with this mobile number already exists.',
      );
    }
  }

  Future<void> _setArchived(String id, bool archived) async {
    final index = DemoData.clients.indexWhere((client) => client.id == id);
    if (index < 0) throw const RepositoryException('Client was not found.');
    DemoData.clients[index] = DemoData.clients[index].copyWith(
      isArchived: archived,
    );
  }

  @override
  Future<List<Service>> getServices({bool includeArchived = false}) async {
    return List.unmodifiable(
      includeArchived
          ? DemoData.services
          : DemoData.services.where((service) => service.isActive),
    );
  }

  @override
  Future<Service?> getServiceById(String id) async {
    for (final service in DemoData.services) {
      if (service.id == id) return service;
    }
    return null;
  }

  @override
  Future<List<Service>> searchServices(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    final services = await getServices();
    if (normalizedQuery.isEmpty) return services;
    return services
        .where(
          (service) =>
              service.name.toLowerCase().contains(normalizedQuery) ||
              service.category.label.toLowerCase().contains(normalizedQuery),
        )
        .toList();
  }

  @override
  Future<List<Service>> getServicesByCategory(
    ServiceCategory category, {
    bool includeArchived = false,
  }) async {
    final services = await getServices(includeArchived: includeArchived);
    return services.where((service) => service.category == category).toList();
  }

  @override
  Future<Service> createService({
    required String name,
    required ServiceCategory category,
    required int durationMinutes,
    required double price,
    required String description,
    required List<String> assignedEmployeeIds,
  }) async {
    _validateService(name, durationMinutes, price);
    final now = DateTime.now();
    final service = Service(
      id: 'svc_${DemoData.services.length + 1}',
      name: name.trim(),
      description: description.trim(),
      durationMinutes: durationMinutes,
      price: price,
      category: category,
      isActive: true,
      createdAt: now,
      updatedAt: now,
      assignedEmployeeIds: List.unmodifiable(assignedEmployeeIds),
      historicalName: name.trim(),
      historicalCategory: category,
      historicalDurationMinutes: durationMinutes,
      historicalPrice: price,
    );
    DemoData.services.add(service);
    return service;
  }

  @override
  Future<Service> updateService({
    required String id,
    required String name,
    required ServiceCategory category,
    required int durationMinutes,
    required double price,
    required String description,
    required List<String> assignedEmployeeIds,
  }) async {
    _validateService(name, durationMinutes, price);
    final index = DemoData.services.indexWhere((service) => service.id == id);
    if (index < 0) throw const RepositoryException('Service was not found.');
    final current = DemoData.services[index];
    final updated = current.copyWith(
      name: name.trim(),
      category: category,
      durationMinutes: durationMinutes,
      price: price,
      description: description.trim(),
      assignedEmployeeIds: assignedEmployeeIds,
    );
    DemoData.services[index] = updated;
    return updated;
  }

  @override
  Future<void> archiveService(String id) async {
    await _setServiceActive(id, false);
  }

  @override
  Future<void> restoreService(String id) async {
    await _setServiceActive(id, true);
  }

  void _validateService(String name, int durationMinutes, double price) {
    if (name.trim().isEmpty) {
      throw const RepositoryException('Service name is required.');
    }
    if (durationMinutes <= 0) {
      throw const RepositoryException('Duration must be greater than zero.');
    }
    if (price < 0) {
      throw const RepositoryException('Price cannot be negative.');
    }
  }

  Future<void> _setServiceActive(String id, bool isActive) async {
    final index = DemoData.services.indexWhere((service) => service.id == id);
    if (index < 0) throw const RepositoryException('Service was not found.');
    final service = DemoData.services[index];
    DemoData.services[index] = service.copyWith(
      name: service.name,
      category: service.category,
      durationMinutes: service.durationMinutes,
      price: service.price,
      description: service.description,
      assignedEmployeeIds: service.assignedEmployeeIds,
      isActive: isActive,
    );
  }

  @override
  Future<List<Appointment>> getAppointments() async {
    await _ensurePersistedAppointmentsLoaded();
    return List.unmodifiable(DemoData.appointments);
  }

  @override
  Future<Appointment?> getAppointmentById(String id) async {
    await _ensurePersistedAppointmentsLoaded();
    for (final appointment in DemoData.appointments) {
      if (appointment.id == id) return appointment;
    }
    return null;
  }

  @override
  Future<AvailabilityResult> checkAvailability({
    required DateTime startAt,
    required List<AppointmentService> services,
    String? excludingAppointmentId,
  }) async {
    final drafts = <AppointmentDraftService>[];
    for (final item in services) {
      final service = await getServiceById(item.serviceId);
      if (service == null) {
        return const AvailabilityResult.unavailable(
          'Selected service is unavailable.',
        );
      }
      if (item.employeeId == null || item.employeeName == null) {
        return const AvailabilityResult.unavailable(
          'Every service needs an assigned employee.',
        );
      }
      final employee = await getEmployeeById(item.employeeId!);
      if (employee == null || !employee.isActive) {
        return const AvailabilityResult.unavailable(
          'The selected employee is no longer available for new appointments.',
        );
      }
      if (!item.isCapabilityOverride &&
          !employee.serviceIds.contains(item.serviceId)) {
        return const AvailabilityResult.unavailable(
          'This employee is not capable of performing the selected service.',
        );
      }
      drafts.add(
        AppointmentDraftService(
          service: service,
          employeeId: item.employeeId!,
          employeeName: item.employeeName!,
        ),
      );
    }
    return AppointmentScheduler.checkAvailability(
      startAt: startAt,
      services: drafts,
      appointments: DemoData.appointments,
      excludingAppointmentId: excludingAppointmentId,
    );
  }

  @override
  Future<Appointment> createAppointment({
    required String clientId,
    required String clientName,
    required DateTime startAt,
    required List<AppointmentService> services,
    Reminder? reminder,
    String? createdBy,
  }) async {
    await _ensurePersistedAppointmentsLoaded();
    final availability = await checkAvailability(
      startAt: startAt,
      services: services,
    );
    if (!availability.isAvailable) {
      throw RepositoryException(availability.reason!);
    }
    final now = DateTime.now();
    final appointment = Appointment(
      id: 'appt_${DemoData.appointments.length + 1}',
      clientId: clientId,
      clientName: clientName,
      employeeId: services.first.employeeId,
      employeeName: services.first.employeeName,
      startAt: startAt,
      endAt: startAt.add(
        Duration(
          minutes: services.fold(0, (sum, item) => sum + item.durationMinutes),
        ),
      ),
      status: AppointmentStatus.confirmed,
      services: List.unmodifiable(services),
      createdAt: now,
      updatedAt: now,
      createdBy: createdBy,
      reminder: reminder,
    );
    DemoData.appointments.add(appointment);
    await _persistAppointments();
    return appointment;
  }

  @override
  Future<Appointment> updateAppointment(Appointment appointment) async {
    await _ensurePersistedAppointmentsLoaded();
    final availability = await checkAvailability(
      startAt: appointment.startAt,
      services: appointment.services,
      excludingAppointmentId: appointment.id,
    );
    if (!availability.isAvailable) {
      throw RepositoryException(availability.reason!);
    }
    final index = DemoData.appointments.indexWhere(
      (item) => item.id == appointment.id,
    );
    if (index < 0) {
      throw const RepositoryException('Appointment was not found.');
    }
    final updated = Appointment(
      id: appointment.id,
      clientId: appointment.clientId,
      clientName: appointment.clientName,
      employeeId: appointment.services.first.employeeId,
      employeeName: appointment.services.first.employeeName,
      startAt: appointment.startAt,
      endAt: appointment.endAt,
      status: appointment.status,
      paymentStatus: appointment.paymentStatus,
      services: appointment.services,
      notes: appointment.notes,
      source: appointment.source,
      createdAt: appointment.createdAt,
      updatedAt: DateTime.now(),
      createdBy: appointment.createdBy,
      reminder: appointment.reminder,
      cancellationReason: appointment.cancellationReason,
      cancelledBy: appointment.cancelledBy,
      cancelledAt: appointment.cancelledAt,
    );
    DemoData.appointments[index] = updated;
    await _persistAppointments();
    return updated;
  }

  @override
  Future<Appointment> cancelAppointment({
    required String id,
    required String reason,
    required String cancelledBy,
  }) async {
    await _ensurePersistedAppointmentsLoaded();
    final appointment = await getAppointmentById(id);
    if (appointment == null) {
      throw const RepositoryException('Appointment was not found.');
    }
    final updated = _withStatus(
      appointment,
      AppointmentStatus.cancelled,
      cancellationReason: reason,
      cancelledBy: cancelledBy,
    );
    _replaceAppointment(updated);
    await _persistAppointments();
    return updated;
  }

  @override
  Future<Appointment> markNoShow(String id) async {
    await _ensurePersistedAppointmentsLoaded();
    final appointment = await getAppointmentById(id);
    if (appointment == null) {
      throw const RepositoryException('Appointment was not found.');
    }
    final updated = _withStatus(appointment, AppointmentStatus.noShow);
    _replaceAppointment(updated);
    await _persistAppointments();
    return updated;
  }

  @override
  Future<Appointment> completeAppointment(String id) async {
    await _ensurePersistedAppointmentsLoaded();
    final appointment = await getAppointmentById(id);
    if (appointment == null) {
      throw const RepositoryException('Appointment was not found.');
    }
    final updated = _withStatus(appointment, AppointmentStatus.completed);
    _replaceAppointment(updated);
    await _persistAppointments();
    return updated;
  }

  Appointment _withStatus(
    Appointment appointment,
    AppointmentStatus status, {
    String? cancellationReason,
    String? cancelledBy,
  }) {
    return Appointment(
      id: appointment.id,
      clientId: appointment.clientId,
      clientName: appointment.clientName,
      employeeId: appointment.employeeId,
      employeeName: appointment.employeeName,
      startAt: appointment.startAt,
      endAt: appointment.endAt,
      status: status,
      paymentStatus: appointment.paymentStatus,
      services: appointment.services,
      notes: appointment.notes,
      source: appointment.source,
      createdAt: appointment.createdAt,
      updatedAt: DateTime.now(),
      createdBy: appointment.createdBy,
      reminder: appointment.reminder,
      cancellationReason: cancellationReason,
      cancelledBy: cancelledBy,
      cancelledAt: status == AppointmentStatus.cancelled
          ? DateTime.now()
          : null,
    );
  }

  void _replaceAppointment(Appointment appointment) {
    final index = DemoData.appointments.indexWhere(
      (item) => item.id == appointment.id,
    );
    DemoData.appointments[index] = appointment;
  }

  @override
  Future<List<Employee>> getEmployees({bool includeArchived = false}) async {
    return List.unmodifiable(
      includeArchived
          ? DemoData.employees
          : DemoData.employees.where((employee) => employee.isActive),
    );
  }

  @override
  Future<Employee?> getEmployeeById(String id) async {
    for (final employee in DemoData.employees) {
      if (employee.id == id) return employee;
    }
    return null;
  }

  @override
  Future<List<Employee>> searchEmployees(
    String query, {
    bool includeArchived = false,
  }) async {
    final normalized = query.trim().toLowerCase();
    final employees = await getEmployees(includeArchived: includeArchived);
    if (normalized.isEmpty) return employees;
    return employees
        .where(
          (employee) =>
              employee.fullName.toLowerCase().contains(normalized) ||
              employee.id.toLowerCase().contains(normalized) ||
              (employee.email ?? '').toLowerCase().contains(normalized),
        )
        .toList();
  }

  @override
  Future<Employee> createEmployee({
    required String id,
    required String name,
    required String phone,
    required String pin,
    required List<String> serviceIds,
    String? email,
    int experienceYears = 0,
  }) async {
    if (id.trim().isEmpty || name.trim().isEmpty || phone.trim().isEmpty) {
      throw const RepositoryException(
        'Employee ID, name, and mobile are required.',
      );
    }
    if (pin.trim().length < 4) {
      throw const RepositoryException(
        'PIN must contain at least 4 characters.',
      );
    }
    if (serviceIds.isEmpty) {
      throw const RepositoryException(
        'Assign at least one service capability.',
      );
    }
    if (DemoData.employees.any(
      (employee) => employee.id.toLowerCase() == id.trim().toLowerCase(),
    )) {
      throw const RepositoryException('That Employee ID is already in use.');
    }
    final now = DateTime.now();
    final employee = Employee(
      id: id.trim(),
      fullName: name.trim(),
      role: 'Stylist',
      phone: phone.trim(),
      email: email?.trim().isEmpty == true ? null : email?.trim(),
      isActive: true,
      createdAt: now,
      updatedAt: now,
      experienceYears: experienceYears,
      serviceIds: List.unmodifiable(serviceIds),
    );
    DemoData.employees.add(employee);
    DemoData.employeePins[employee.id] = pin.trim();
    _syncEmployeeCapabilities(employee.id, serviceIds);
    return employee;
  }

  @override
  Future<Employee> updateEmployee({
    required String id,
    required String name,
    required String phone,
    required List<String> serviceIds,
    String? email,
    int experienceYears = 0,
  }) async {
    if (name.trim().isEmpty || phone.trim().isEmpty || serviceIds.isEmpty) {
      throw const RepositoryException(
        'Name, mobile, and at least one capability are required.',
      );
    }
    final index = DemoData.employees.indexWhere(
      (employee) => employee.id == id,
    );
    if (index < 0) throw const RepositoryException('Employee was not found.');
    final updated = DemoData.employees[index].copyWith(
      fullName: name.trim(),
      phone: phone.trim(),
      email: email?.trim(),
      experienceYears: experienceYears,
      serviceIds: serviceIds,
    );
    DemoData.employees[index] = updated;
    _syncEmployeeCapabilities(id, serviceIds);
    return updated;
  }

  @override
  Future<void> archiveEmployee(String id) async {
    await _setEmployeeActive(id, false);
  }

  @override
  Future<void> restoreEmployee(String id) async {
    await _setEmployeeActive(id, true);
  }

  @override
  Future<void> resetEmployeePin(String id, String newPin) async {
    if (newPin.trim().length < 4) {
      throw const RepositoryException(
        'PIN must contain at least 4 characters.',
      );
    }
    final index = DemoData.employees.indexWhere(
      (employee) => employee.id == id,
    );
    if (index < 0) throw const RepositoryException('Employee was not found.');
    DemoData.employees[index] = DemoData.employees[index].copyWith(
      pinLastResetAt: DateTime.now(),
    );
    DemoData.employeePins[id] = newPin.trim();
  }

  @override
  Future<List<Appointment>> getEmployeeAppointments(String employeeId) async {
    return DemoData.appointments
        .where(
          (appointment) => appointment.services.any(
            (service) => service.employeeId == employeeId,
          ),
        )
        .toList();
  }

  @override
  Future<List<EmployeeRewardTransaction>> getEmployeeRewardHistory(
    String employeeId,
  ) async {
    return DemoData.employeeRewards
        .where((transaction) => transaction.employeeId == employeeId)
        .toList();
  }

  @override
  Future<Employee> adjustEmployeeXp({
    required String employeeId,
    required int amount,
    required String reason,
    required String performedBy,
  }) async {
    if (amount == 0 || reason.trim().isEmpty) {
      throw const RepositoryException('Enter a non-zero XP amount and reason.');
    }
    final index = DemoData.employees.indexWhere(
      (employee) => employee.id == employeeId,
    );
    if (index < 0) throw const RepositoryException('Employee was not found.');
    final employee = DemoData.employees[index];
    if (employee.rewardXp + amount < 0) {
      throw const RepositoryException('Employee XP cannot be negative.');
    }
    DemoData.employeeRewards.add(
      EmployeeRewardTransaction(
        id: 'reward_${DemoData.employeeRewards.length + 1}',
        employeeId: employeeId,
        amount: amount,
        reason: reason.trim(),
        performedBy: performedBy,
        createdAt: DateTime.now(),
      ),
    );
    final updated = employee.copyWith(rewardXp: employee.rewardXp + amount);
    DemoData.employees[index] = updated;
    return updated;
  }

  Future<void> _setEmployeeActive(String id, bool isActive) async {
    final index = DemoData.employees.indexWhere(
      (employee) => employee.id == id,
    );
    if (index < 0) throw const RepositoryException('Employee was not found.');
    DemoData.employees[index] = DemoData.employees[index].copyWith(
      isActive: isActive,
    );
  }

  void _syncEmployeeCapabilities(String employeeId, List<String> serviceIds) {
    for (var index = 0; index < DemoData.services.length; index++) {
      final service = DemoData.services[index];
      final employeeIds = service.assignedEmployeeIds
          .where((id) => id != employeeId)
          .toList();
      if (serviceIds.contains(service.id)) employeeIds.add(employeeId);
      DemoData.services[index] = service.copyWith(
        name: service.name,
        category: service.category,
        durationMinutes: service.durationMinutes,
        price: service.price,
        description: service.description,
        assignedEmployeeIds: employeeIds,
      );
    }
  }

  @override
  Future<List<Payment>> getPayments() async {
    return List.unmodifiable(DemoData.payments);
  }

  @override
  Future<Payment?> getPaymentByInvoiceId(String invoiceId) async {
    for (final payment in DemoData.payments) {
      if (payment.invoiceId == invoiceId) return payment;
    }
    return null;
  }

  @override
  Future<Payment> createPaymentRecord({
    required Invoice invoice,
    required PaymentMethod method,
  }) async {
    final existing = await getPaymentByInvoiceId(invoice.id);
    if (existing != null) return existing;
    final payment = Payment(
      id: 'payment_${DemoData.payments.length + 1}',
      appointmentId: invoice.appointmentId,
      invoiceId: invoice.id,
      clientId: invoice.clientId,
      amount: invoice.total,
      method: method,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
    );
    DemoData.payments.add(payment);
    return payment;
  }

  @override
  Future<Payment> createAppointmentPaymentRecord({
    required Appointment appointment,
    required double amount,
    required PaymentMethod method,
  }) async {
    final existing = DemoData.payments
        .where((payment) => payment.appointmentId == appointment.id)
        .firstOrNull;
    if (existing != null) return existing;
    final payment = Payment(
      id: 'payment_${DemoData.payments.length + 1}',
      appointmentId: appointment.id,
      invoiceId: '',
      clientId: appointment.clientId,
      amount: amount,
      method: method,
      status: PaymentStatus.pending,
      createdAt: DateTime.now(),
    );
    DemoData.payments.add(payment);
    return payment;
  }

  @override
  Future<Payment> verifyPaymentRecord({
    required String paymentId,
    required String transactionId,
  }) async {
    final index = DemoData.payments.indexWhere(
      (payment) => payment.id == paymentId,
    );
    if (index < 0) {
      throw const RepositoryException('Payment was not found.');
    }
    final payment = DemoData.payments[index];
    if (payment.status == PaymentStatus.paid) return payment;
    if (payment.status == PaymentStatus.refunded) {
      throw const RepositoryException(
        'This payment has already been refunded.',
      );
    }
    if (transactionId.trim().isEmpty) {
      throw const RepositoryException('A payment reference is required.');
    }
    final now = DateTime.now();
    final verified = payment.copyWith(
      status: PaymentStatus.paid,
      transactionId: transactionId.trim(),
      paidAt: now,
    );
    DemoData.payments[index] = verified;
    final appointmentIndex = DemoData.appointments.indexWhere(
      (appointment) => appointment.id == payment.appointmentId,
    );
    if (appointmentIndex >= 0) {
      final appointment = DemoData.appointments[appointmentIndex];
      DemoData.appointments[appointmentIndex] = Appointment(
        id: appointment.id,
        clientId: appointment.clientId,
        clientName: appointment.clientName,
        employeeId: appointment.employeeId,
        employeeName: appointment.employeeName,
        startAt: appointment.startAt,
        endAt: appointment.endAt,
        status: appointment.status,
        paymentStatus: PaymentStatus.paid,
        services: appointment.services,
        notes: appointment.notes,
        source: appointment.source,
        createdAt: appointment.createdAt,
        updatedAt: now,
        createdBy: appointment.createdBy,
        reminder: appointment.reminder,
        cancellationReason: appointment.cancellationReason,
        cancelledBy: appointment.cancelledBy,
        cancelledAt: appointment.cancelledAt,
      );
      await _persistAppointments();
    }
    final invoiceIndex = DemoData.invoices.indexWhere(
      (invoice) => invoice.id == payment.invoiceId,
    );
    if (invoiceIndex >= 0) {
      final invoice = DemoData.invoices[invoiceIndex];
      DemoData.invoices[invoiceIndex] = invoice.copyWithPayment(
        paymentStatus: PaymentStatus.paid,
        paymentMethod: payment.method,
        transactionId: transactionId.trim(),
        amountPaid: payment.amount,
        paymentDate: now,
      );
    }
    await _updateClientAfterVerifiedPayment(payment);
    return verified;
  }

  @override
  Future<Payment> failPayment({
    required String paymentId,
    String? reason,
  }) async {
    final index = DemoData.payments.indexWhere(
      (payment) => payment.id == paymentId,
    );
    if (index < 0) throw const RepositoryException('Payment was not found.');
    final failed = DemoData.payments[index].copyWith(
      status: PaymentStatus.failed,
      failureReason: reason ?? 'Payment was not verified.',
    );
    DemoData.payments[index] = failed;
    return failed;
  }

  @override
  Future<Payment> refundPayment({
    required String paymentId,
    required String refundReference,
  }) async {
    final index = DemoData.payments.indexWhere(
      (payment) => payment.id == paymentId,
    );
    if (index < 0) throw const RepositoryException('Payment was not found.');
    final payment = DemoData.payments[index];
    if (payment.status != PaymentStatus.paid) {
      throw const RepositoryException('Only paid payments can be refunded.');
    }
    if (refundReference.trim().isEmpty) {
      throw const RepositoryException('A refund reference is required.');
    }
    final refunded = payment.copyWith(
      status: PaymentStatus.refunded,
      refundedAt: DateTime.now(),
      refundReference: refundReference.trim(),
    );
    DemoData.payments[index] = refunded;
    final invoiceIndex = DemoData.invoices.indexWhere(
      (invoice) => invoice.id == payment.invoiceId,
    );
    if (invoiceIndex >= 0) {
      final invoice = DemoData.invoices[invoiceIndex];
      DemoData.invoices[invoiceIndex] = invoice.copyWithPayment(
        paymentStatus: PaymentStatus.refunded,
        paymentMethod: payment.method,
        transactionId: payment.transactionId ?? refundReference,
        amountPaid: 0,
        paymentDate: DateTime.now(),
      );
    }
    return refunded;
  }

  Future<void> _updateClientAfterVerifiedPayment(Payment payment) async {
    final appointmentIndex = DemoData.appointments.indexWhere(
      (appointment) => appointment.id == payment.appointmentId,
    );
    if (appointmentIndex < 0) {
      return;
    }
    final appointment = DemoData.appointments[appointmentIndex];
    if (appointment.status != AppointmentStatus.completed) return;
    final clientIndex = DemoData.clients.indexWhere(
      (client) => client.id == payment.clientId,
    );
    if (clientIndex < 0) {
      return;
    }
    final history = await getClientHistory(payment.clientId);
    final paidVisits = history.appointments
        .where(
          (item) =>
              item.status == AppointmentStatus.completed &&
              history.payments.any(
                (itemPayment) =>
                    itemPayment.appointmentId == item.id &&
                    itemPayment.status == PaymentStatus.paid,
              ),
        )
        .length;
    final client = DemoData.clients[clientIndex];
    DemoData.clients[clientIndex] = client.copyWith(
      visitCount: paidVisits,
      isVip: paidVisits >= 3,
      loyaltyPoints: client.loyaltyPoints + 10,
    );
  }

  @override
  Future<List<Invoice>> getInvoices() async {
    return List.unmodifiable(DemoData.invoices);
  }

  @override
  Future<Invoice?> getInvoiceById(String id) async {
    for (final invoice in DemoData.invoices) {
      if (invoice.id == id) return invoice;
    }
    return null;
  }

  @override
  Future<Invoice?> getInvoiceByAppointmentId(String appointmentId) async {
    for (final invoice in DemoData.invoices) {
      if (invoice.appointmentId == appointmentId) return invoice;
    }
    return null;
  }

  @override
  Future<BillingQuote> calculateInvoice({
    required String appointmentId,
    required DiscountType discountType,
    required double discountValue,
  }) async {
    final appointment = await getAppointmentById(appointmentId);
    if (appointment == null) {
      throw const RepositoryException('Appointment was not found.');
    }
    return BillingCalculator.calculate(
      originalAmount: appointment.services.fold(
        0,
        (total, service) => total + (service.historicalPrice ?? service.price),
      ),
      discountType: discountType,
      discountValue: discountValue,
    );
  }

  @override
  Future<Invoice> createInvoice({
    required String appointmentId,
    required DiscountType discountType,
    required double discountValue,
  }) async {
    final existing = await getInvoiceByAppointmentId(appointmentId);
    if (existing != null) return existing;
    final appointment = await getAppointmentById(appointmentId);
    if (appointment == null) {
      throw const RepositoryException('Appointment was not found.');
    }
    if (appointment.status != AppointmentStatus.completed) {
      throw const RepositoryException(
        'Complete the appointment before generating a bill.',
      );
    }
    final quote = await calculateInvoice(
      appointmentId: appointmentId,
      discountType: discountType,
      discountValue: discountValue,
    );
    final lineItems = BillingCalculator.lineItemsFor(appointment);
    final discountRatio = quote.originalAmount == 0
        ? 0
        : quote.discountAmount / quote.originalAmount;
    final adjustedLineItems = lineItems
        .map(
          (item) => InvoiceLineItem(
            serviceName: item.serviceName,
            employeeName: item.employeeName,
            durationMinutes: item.durationMinutes,
            originalPrice: item.originalPrice,
            discountAmount: item.originalPrice * discountRatio,
            finalAmount: item.originalPrice * (1 - discountRatio),
          ),
        )
        .toList();
    final now = DateTime.now();
    final invoice = Invoice(
      id: 'invoice_${DemoData.invoices.length + 1}',
      invoiceNumber: _nextInvoiceNumber(),
      appointmentId: appointment.id,
      clientId: appointment.clientId,
      clientName: appointment.clientName,
      salonName: DemoData.businessProfile.salonName,
      subtotal: quote.originalAmount,
      tax: 0,
      total: quote.finalAmount,
      issuedAt: now,
      isPaid: false,
      lineItems: adjustedLineItems,
      discountType: discountType,
      discountValue: discountValue,
      discountAmount: quote.discountAmount,
      paymentStatus: PaymentStatus.pending,
      amountPaid: 0,
      balance: quote.balance,
    );
    DemoData.invoices.add(invoice);
    return invoice;
  }

  String _nextInvoiceNumber() {
    final number = DemoData.invoices.length + 1001;
    return 'GLM-$number';
  }

  @override
  Future<List<InventoryProduct>> getProducts({
    bool includeArchived = false,
  }) async {
    return List.unmodifiable(
      includeArchived
          ? DemoData.inventoryProducts
          : DemoData.inventoryProducts.where((product) => product.isActive),
    );
  }

  @override
  Future<InventoryProduct?> getProductById(String id) async {
    for (final product in DemoData.inventoryProducts) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<List<InventoryTransaction>> getInventoryTransactions(
    String productId,
  ) async => List.unmodifiable(
    DemoData.inventoryTransactions.where((item) => item.productId == productId),
  );

  @override
  Future<InventoryProduct> createProduct({
    required String name,
    required String category,
    required double cost,
    required int quantity,
    required int lowStockThreshold,
    required String performedBy,
  }) async {
    _validateProduct(name, category, cost, quantity, lowStockThreshold);
    final now = DateTime.now();
    final product = InventoryProduct(
      id: 'inv_${DemoData.inventoryProducts.length + 1}',
      name: name.trim(),
      category: category.trim(),
      quantityOnHand: quantity,
      unitPrice: cost,
      lowStockThreshold: lowStockThreshold,
      updatedAt: now,
    );
    DemoData.inventoryProducts.add(product);
    if (quantity > 0)
      _recordInventoryTransaction(
        product: product,
        type: InventoryTransactionType.stockIn,
        quantity: quantity,
        previousQuantity: 0,
        reason: 'Opening stock',
        performedBy: performedBy,
      );
    return product;
  }

  @override
  Future<InventoryProduct> updateProduct({
    required String id,
    required String name,
    required String category,
    required double cost,
    required int lowStockThreshold,
    int? quantity,
    String? adjustmentReason,
    required String performedBy,
  }) async {
    final current = await getProductById(id);
    if (current == null)
      throw const RepositoryException('Product was not found.');
    final nextQuantity = quantity ?? current.quantityOnHand;
    _validateProduct(name, category, cost, nextQuantity, lowStockThreshold);
    final index = DemoData.inventoryProducts.indexWhere(
      (item) => item.id == id,
    );
    final updated = current.copyWith(
      name: name.trim(),
      category: category.trim(),
      unitPrice: cost,
      lowStockThreshold: lowStockThreshold,
      quantityOnHand: nextQuantity,
    );
    DemoData.inventoryProducts[index] = updated;
    if (nextQuantity != current.quantityOnHand) {
      _recordInventoryTransaction(
        product: updated,
        type: InventoryTransactionType.adjustment,
        quantity: nextQuantity - current.quantityOnHand,
        previousQuantity: current.quantityOnHand,
        reason: adjustmentReason?.trim().isEmpty == false
            ? adjustmentReason!.trim()
            : 'Manual adjustment',
        performedBy: performedBy,
      );
    }
    return updated;
  }

  @override
  Future<InventoryProduct> changeStock({
    required String productId,
    required InventoryTransactionType type,
    required int quantity,
    required String reason,
    required String performedBy,
  }) async {
    final current = await getProductById(productId);
    if (current == null)
      throw const RepositoryException('Product was not found.');
    if (!current.isActive)
      throw const RepositoryException(
        'Restore this product before recording stock.',
      );
    if ((type != InventoryTransactionType.adjustment && quantity <= 0) ||
        quantity < 0 ||
        reason.trim().isEmpty) {
      throw const RepositoryException('Enter a valid quantity and reason.');
    }
    final delta = type == InventoryTransactionType.stockOut
        ? -quantity
        : quantity;
    final nextQuantity = type == InventoryTransactionType.adjustment
        ? quantity
        : current.quantityOnHand + delta;
    if (nextQuantity < 0)
      throw const RepositoryException('Stock cannot become negative.');
    final index = DemoData.inventoryProducts.indexWhere(
      (item) => item.id == productId,
    );
    final updated = current.copyWith(quantityOnHand: nextQuantity);
    DemoData.inventoryProducts[index] = updated;
    _recordInventoryTransaction(
      product: updated,
      type: type,
      quantity: type == InventoryTransactionType.adjustment
          ? nextQuantity - current.quantityOnHand
          : delta,
      previousQuantity: current.quantityOnHand,
      reason: reason.trim(),
      performedBy: performedBy,
    );
    return updated;
  }

  @override
  Future<void> archiveProduct(String id) => _setProductActive(id, false);

  @override
  Future<void> restoreProduct(String id) => _setProductActive(id, true);

  Future<void> _setProductActive(String id, bool isActive) async {
    final index = DemoData.inventoryProducts.indexWhere(
      (item) => item.id == id,
    );
    if (index < 0) throw const RepositoryException('Product was not found.');
    DemoData.inventoryProducts[index] = DemoData.inventoryProducts[index]
        .copyWith(isActive: isActive);
  }

  void _validateProduct(
    String name,
    String category,
    double cost,
    int quantity,
    int threshold,
  ) {
    if (name.trim().isEmpty || category.trim().isEmpty)
      throw const RepositoryException(
        'Product name and category are required.',
      );
    if (cost < 0) throw const RepositoryException('Cost cannot be negative.');
    if (quantity < 0 || threshold < 0)
      throw const RepositoryException(
        'Quantity and threshold cannot be negative.',
      );
  }

  void _recordInventoryTransaction({
    required InventoryProduct product,
    required InventoryTransactionType type,
    required int quantity,
    required int previousQuantity,
    required String reason,
    required String performedBy,
  }) {
    DemoData.inventoryTransactions.add(
      InventoryTransaction(
        id: 'stock_${DemoData.inventoryTransactions.length + 1}',
        productId: product.id,
        productName: product.name,
        type: type,
        quantity: quantity,
        previousQuantity: previousQuantity,
        newQuantity: product.quantityOnHand,
        reason: reason,
        performedBy: performedBy,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<BusinessProfile> getBusinessProfile() async {
    await _ensurePersistedSettingsLoaded();
    return DemoData.businessProfile;
  }

  @override
  Future<List<BusinessHours>> getBusinessHours() async {
    await _ensurePersistedSettingsLoaded();
    return List.unmodifiable(DemoData.businessHours);
  }

  @override
  Future<List<SalonBreak>> getSalonBreaks() async {
    await _ensurePersistedSettingsLoaded();
    return List.unmodifiable(DemoData.salonBreaks);
  }

  @override
  Future<ApplicationSettings> getApplicationSettings() async {
    await _ensurePersistedSettingsLoaded();
    return DemoData.applicationSettings;
  }

  @override
  Future<BusinessProfile> updateBusinessProfile(BusinessProfile profile) async {
    await _ensurePersistedSettingsLoaded();
    DemoData.businessProfile = profile;
    await _persistSettings();
    return profile;
  }

  @override
  Future<List<BusinessHours>> updateBusinessHours(
    List<BusinessHours> hours,
  ) async {
    await _ensurePersistedSettingsLoaded();
    DemoData.businessHours = List<BusinessHours>.from(hours);
    await _persistSettings();
    return List.unmodifiable(DemoData.businessHours);
  }

  @override
  Future<List<SalonBreak>> updateSalonBreaks(List<SalonBreak> breaks) async {
    await _ensurePersistedSettingsLoaded();
    DemoData.salonBreaks = List<SalonBreak>.from(breaks);
    await _persistSettings();
    return List.unmodifiable(DemoData.salonBreaks);
  }

  @override
  Future<ApplicationSettings> updateApplicationSettings(
    ApplicationSettings settings,
  ) async {
    await _ensurePersistedSettingsLoaded();
    DemoData.applicationSettings = settings;
    await _persistSettings();
    return settings;
  }
}

class RepositoryException implements Exception {
  const RepositoryException(this.message);

  final String message;
}

final _requiredServiceCatalog = <Service>[
  _requiredService(
    1,
    'Eyebrow Threading',
    ServiceCategory.face,
    10,
    '10 min',
    50,
    ['emp_03'],
  ),
  _requiredService(
    2,
    'Upper Lip Threading',
    ServiceCategory.face,
    5,
    '5 min',
    40,
    ['emp_03'],
  ),
  _requiredService(
    3,
    'Full Face Threading',
    ServiceCategory.face,
    20,
    '20 min',
    200,
    ['emp_03'],
  ),
  _requiredService(4, 'Face Waxing', ServiceCategory.face, 20, '20 min', 250, [
    'emp_03',
  ]),
  _requiredService(
    5,
    'Face Cleanup',
    ServiceCategory.face,
    40,
    '30–40 min',
    500,
    ['emp_03'],
  ),
  _requiredService(
    6,
    'Basic Facial',
    ServiceCategory.face,
    60,
    '45–60 min',
    700,
    ['emp_03'],
  ),
  _requiredService(7, 'Gold Facial', ServiceCategory.face, 60, '60 min', 1000, [
    'emp_03',
  ]),
  _requiredService(
    8,
    'Diamond Facial',
    ServiceCategory.face,
    75,
    '60–75 min',
    1500,
    ['emp_03'],
  ),
  _requiredService(
    9,
    'Hydra Facial',
    ServiceCategory.face,
    90,
    '60–90 min',
    3000,
    ['emp_03'],
  ),
  _requiredService(
    10,
    'Face Bleach',
    ServiceCategory.face,
    30,
    '20–30 min',
    400,
    ['emp_03'],
  ),
  _requiredService(
    11,
    'Face De-Tan',
    ServiceCategory.face,
    40,
    '30–40 min',
    500,
    ['emp_03'],
  ),
  _requiredService(12, 'Haircut', ServiceCategory.hair, 45, '30–45 min', 500, [
    'emp_01',
    'emp_02',
  ]),
  _requiredService(
    13,
    'Hair Trim',
    ServiceCategory.hair,
    30,
    '20–30 min',
    300,
    ['emp_01', 'emp_02'],
  ),
  _requiredService(
    14,
    'Hair Wash',
    ServiceCategory.hair,
    30,
    '20–30 min',
    300,
    ['emp_01', 'emp_02'],
  ),
  _requiredService(15, 'Blow Dry', ServiceCategory.hair, 45, '30–45 min', 500, [
    'emp_01',
    'emp_02',
  ]),
  _requiredService(
    16,
    'Hair Styling',
    ServiceCategory.hair,
    60,
    '30–60 min',
    800,
    ['emp_01', 'emp_02'],
  ),
  _requiredService(
    17,
    'Hair Spa',
    ServiceCategory.hair,
    90,
    '60–90 min',
    1200,
    ['emp_01', 'emp_02'],
  ),
  _requiredService(
    18,
    'Anti-Dandruff Treatment',
    ServiceCategory.hair,
    60,
    '60 min',
    1500,
    ['emp_01', 'emp_02'],
  ),
  _requiredService(
    19,
    'Hair Colour',
    ServiceCategory.hair,
    120,
    '90–120 min',
    1500,
    ['emp_01', 'emp_02'],
  ),
  _requiredService(
    20,
    'Root Touch-Up',
    ServiceCategory.hair,
    90,
    '60–90 min',
    1200,
    ['emp_01', 'emp_02'],
  ),
  _requiredService(
    21,
    'Highlights',
    ServiceCategory.hair,
    180,
    '120–180 min',
    2500,
    ['emp_01', 'emp_02'],
  ),
  _requiredService(
    22,
    'Keratin Treatment',
    ServiceCategory.hair,
    180,
    '2–3 hrs',
    4000,
    ['emp_01', 'emp_02'],
  ),
  _requiredService(
    23,
    'Hair Smoothening',
    ServiceCategory.hair,
    180,
    '2–3 hrs',
    3500,
    ['emp_01', 'emp_02'],
  ),
  _requiredService(
    24,
    'Underarm Wax',
    ServiceCategory.bodyWaxing,
    15,
    '15 min',
    200,
    ['emp_03'],
  ),
  _requiredService(
    25,
    'Full Arms Wax',
    ServiceCategory.bodyWaxing,
    30,
    '30 min',
    500,
    ['emp_03'],
  ),
  _requiredService(
    26,
    'Half Legs Wax',
    ServiceCategory.bodyWaxing,
    30,
    '30 min',
    300,
    ['emp_03'],
  ),
  _requiredService(
    27,
    'Full Legs Wax',
    ServiceCategory.bodyWaxing,
    45,
    '45 min',
    600,
    ['emp_03'],
  ),
  _requiredService(
    28,
    'Full Body Wax',
    ServiceCategory.bodyWaxing,
    90,
    '90 min',
    2000,
    ['emp_03'],
  ),
  _requiredService(
    29,
    'Body De-Tan',
    ServiceCategory.bodyWaxing,
    60,
    '45–60 min',
    1000,
    ['emp_03'],
  ),
  _requiredService(
    30,
    'Body Polishing',
    ServiceCategory.bodyWaxing,
    90,
    '60–90 min',
    1500,
    ['emp_03'],
  ),
  _requiredService(
    31,
    'Basic Manicure',
    ServiceCategory.nails,
    45,
    '30–45 min',
    400,
    ['emp_03'],
  ),
  _requiredService(
    32,
    'Spa Manicure',
    ServiceCategory.nails,
    60,
    '45–60 min',
    600,
    ['emp_03'],
  ),
  _requiredService(
    33,
    'Basic Pedicure',
    ServiceCategory.nails,
    60,
    '40–60 min',
    500,
    ['emp_03'],
  ),
  _requiredService(
    34,
    'Spa Pedicure',
    ServiceCategory.nails,
    60,
    '60 min',
    800,
    ['emp_03'],
  ),
  _requiredService(
    35,
    'Nail Polish',
    ServiceCategory.nails,
    20,
    '15–20 min',
    150,
    ['emp_03'],
  ),
  _requiredService(
    36,
    'Gel Polish',
    ServiceCategory.nails,
    45,
    '30–45 min',
    500,
    ['emp_03'],
  ),
  _requiredService(
    37,
    'Nail Art',
    ServiceCategory.nails,
    60,
    '30–60 min',
    500,
    ['emp_03'],
  ),
  _requiredService(
    38,
    'Nail Extensions',
    ServiceCategory.nails,
    90,
    '60–90 min',
    1000,
    ['emp_03'],
  ),
  _requiredService(
    39,
    'Head Massage',
    ServiceCategory.wellness,
    30,
    '20–30 min',
    400,
    ['emp_03'],
  ),
  _requiredService(
    40,
    'Head & Shoulder Massage',
    ServiceCategory.wellness,
    30,
    '30 min',
    600,
    ['emp_03'],
  ),
  _requiredService(
    41,
    'Relaxation Massage',
    ServiceCategory.wellness,
    60,
    '60 min',
    1500,
    ['emp_03'],
  ),
  _requiredService(
    42,
    'Body Spa',
    ServiceCategory.wellness,
    90,
    '60–90 min',
    2000,
    ['emp_03'],
  ),
  _requiredService(
    43,
    'Foot Reflexology',
    ServiceCategory.wellness,
    45,
    '30–45 min',
    700,
    ['emp_03'],
  ),
  _requiredService(
    44,
    'Full Body Scrub',
    ServiceCategory.wellness,
    60,
    '45–60 min',
    1000,
    ['emp_03'],
  ),
  _requiredService(
    45,
    'Beard Trim',
    ServiceCategory.grooming,
    15,
    '15 min',
    150,
    ['emp_01'],
  ),
  _requiredService(
    46,
    'Beard Styling',
    ServiceCategory.grooming,
    20,
    '20 min',
    250,
    ['emp_01'],
  ),
  _requiredService(
    47,
    'Clean Shave',
    ServiceCategory.grooming,
    20,
    '20 min',
    200,
    ['emp_01'],
  ),
  _requiredService(
    48,
    'Beard Colour',
    ServiceCategory.grooming,
    30,
    '30 min',
    500,
    ['emp_01'],
  ),
  _requiredService(
    49,
    'Moustache Trim',
    ServiceCategory.grooming,
    10,
    '10 min',
    100,
    ['emp_01'],
  ),
  _requiredService(
    50,
    "Men's Facial",
    ServiceCategory.grooming,
    60,
    '45–60 min',
    700,
    ['emp_01', 'emp_03'],
  ),
  _requiredService(
    51,
    "Men's Haircut",
    ServiceCategory.grooming,
    45,
    '30–45 min',
    400,
    ['emp_01'],
  ),
  _requiredService(
    52,
    'Basic Makeup',
    ServiceCategory.makeUp,
    60,
    '45–60 min',
    1500,
    ['emp_01', 'emp_03'],
  ),
  _requiredService(
    53,
    'Party Makeup',
    ServiceCategory.makeUp,
    90,
    '60–90 min',
    2500,
    ['emp_01', 'emp_03'],
  ),
  _requiredService(
    54,
    'HD Makeup',
    ServiceCategory.makeUp,
    120,
    '90–120 min',
    3500,
    ['emp_01', 'emp_03'],
  ),
  _requiredService(
    55,
    'Engagement Makeup',
    ServiceCategory.makeUp,
    120,
    '2 hrs',
    6000,
    ['emp_01', 'emp_03'],
  ),
  _requiredService(
    56,
    'Bridal Makeup',
    ServiceCategory.makeUp,
    180,
    '2–3 hrs',
    12000,
    ['emp_01', 'emp_03'],
  ),
  _requiredService(
    57,
    'Eye Makeup',
    ServiceCategory.makeUp,
    30,
    '20–30 min',
    500,
    ['emp_01', 'emp_03'],
  ),
  _requiredService(
    58,
    'Saree Draping',
    ServiceCategory.makeUp,
    30,
    '20–30 min',
    500,
    ['emp_01', 'emp_03'],
  ),
  _requiredService(
    59,
    'Party Hair Styling',
    ServiceCategory.events,
    60,
    '45–60 min',
    800,
    ['emp_01', 'emp_02'],
  ),
  _requiredService(
    60,
    'Party Makeup',
    ServiceCategory.events,
    90,
    '60–90 min',
    2500,
    ['emp_01', 'emp_03'],
  ),
  _requiredService(
    61,
    'Event Makeup + Hair',
    ServiceCategory.events,
    120,
    '2 hrs',
    3500,
    ['emp_01', 'emp_02', 'emp_03'],
  ),
  _requiredService(
    62,
    'Engagement Makeup + Hair',
    ServiceCategory.events,
    180,
    '2–3 hrs',
    7000,
    ['emp_01', 'emp_02', 'emp_03'],
  ),
  _requiredService(
    63,
    'Bridal Makeup + Hair',
    ServiceCategory.events,
    240,
    '3–4 hrs',
    15000,
    ['emp_01', 'emp_02', 'emp_03'],
  ),
  _requiredService(
    64,
    'Bridal Hair Styling',
    ServiceCategory.events,
    90,
    '60–90 min',
    2000,
    ['emp_01', 'emp_02'],
  ),
  _requiredService(
    65,
    'Pre-Bridal Package',
    ServiceCategory.events,
    480,
    'Multiple sessions',
    15000,
    ['emp_01', 'emp_02', 'emp_03'],
    priceLabel: '₹10,000–₹20,000',
  ),
];

Service _requiredService(
  int number,
  String name,
  ServiceCategory category,
  int durationMinutes,
  String durationLabel,
  double price,
  List<String> employeeIds, {
  String? priceLabel,
}) {
  return Service(
    id: 'catalog_svc_${number.toString().padLeft(2, '0')}',
    name: name,
    description: 'Glamora local demo service.',
    durationMinutes: durationMinutes,
    durationLabel: durationLabel,
    price: price,
    priceLabel: priceLabel ?? '₹${price.toStringAsFixed(0)}',
    category: category,
    isActive: true,
    createdAt: DateTime(2025, 1, 1),
    assignedEmployeeIds: employeeIds,
  );
}

class DemoData {
  static ApplicationSettings applicationSettings = const ApplicationSettings(
    defaultAppointmentDuration: 45,
    reminderHours: 24,
    notificationsEnabled: true,
    customerBookingUrl: 'https://glamora.example.com/book',
  );
  static List<BusinessHours> businessHours =
      [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ]
          .map(
            (day) => BusinessHours(
              id: 'hours_$day',
              dayName: day,
              openTime: '09:00',
              closeTime: '18:00',
              isClosed: day == 'Sunday',
            ),
          )
          .toList();
  static List<SalonBreak> salonBreaks = [
    SalonBreak(
      id: 'break_demo_01',
      title: 'Team lunch',
      startTime: '13:00',
      endTime: '14:00',
      date: DateTime(2025, 7, 15),
    ),
  ];
  static final Map<String, String> employeePins = {'emp_01': '2468'};
  static BusinessProfile businessProfile = BusinessProfile(
    id: 'bp_01',
    salonName: 'Glamora',
    tagline: 'Luxury salon care',
    address: '8 Mercer Avenue, Bengaluru',
    phone: '+91 98765 43210',
    email: 'hello@glamora.in',
    logoUrl: null,
    createdAt: DateTime(2024, 1, 5),
  );

  static final List<Employee> employees = [
    Employee(
      id: 'emp_01',
      fullName: 'Aarohi Mehta',
      role: 'Senior Stylist',
      specialty: 'Precision cuts',
      phone: '+91 90000 11100',
      email: 'aarohi@glamora.in',
      isActive: true,
      createdAt: DateTime(2024, 2, 10),
      experienceYears: 8,
      serviceIds: [
        'svc_01',
        'svc_04',
        'svc_07',
        'svc_08',
        'catalog_svc_12',
        'catalog_svc_13',
        'catalog_svc_14',
        'catalog_svc_15',
        'catalog_svc_16',
        'catalog_svc_17',
        'catalog_svc_18',
        'catalog_svc_19',
        'catalog_svc_20',
        'catalog_svc_21',
        'catalog_svc_22',
        'catalog_svc_23',
        'catalog_svc_45',
        'catalog_svc_46',
        'catalog_svc_47',
        'catalog_svc_48',
        'catalog_svc_49',
        'catalog_svc_50',
        'catalog_svc_51',
        'catalog_svc_52',
        'catalog_svc_53',
        'catalog_svc_54',
        'catalog_svc_55',
        'catalog_svc_56',
        'catalog_svc_57',
        'catalog_svc_58',
        'catalog_svc_59',
        'catalog_svc_60',
        'catalog_svc_61',
        'catalog_svc_62',
        'catalog_svc_63',
        'catalog_svc_64',
        'catalog_svc_65',
      ],
      rewardXp: 180,
    ),
    Employee(
      id: 'emp_02',
      fullName: 'Ishaan Verma',
      role: 'Colour Specialist',
      specialty: 'Balayage',
      phone: '+91 90000 22200',
      email: 'ishaan@glamora.in',
      isActive: true,
      createdAt: DateTime(2024, 2, 12),
      experienceYears: 6,
      serviceIds: [
        'svc_02',
        'catalog_svc_12',
        'catalog_svc_13',
        'catalog_svc_14',
        'catalog_svc_15',
        'catalog_svc_16',
        'catalog_svc_17',
        'catalog_svc_18',
        'catalog_svc_19',
        'catalog_svc_20',
        'catalog_svc_21',
        'catalog_svc_22',
        'catalog_svc_23',
        'catalog_svc_59',
        'catalog_svc_61',
        'catalog_svc_62',
        'catalog_svc_63',
        'catalog_svc_64',
        'catalog_svc_65',
      ],
      rewardXp: 240,
    ),
    Employee(
      id: 'emp_03',
      fullName: 'Naina Kapoor',
      role: 'Skin Therapist',
      specialty: 'Facials',
      phone: '+91 90000 33300',
      email: 'naina@glamora.in',
      isActive: true,
      createdAt: DateTime(2024, 2, 18),
      experienceYears: 5,
      serviceIds: [
        'svc_03',
        'svc_05',
        'svc_06',
        'svc_09',
        'catalog_svc_01',
        'catalog_svc_02',
        'catalog_svc_03',
        'catalog_svc_04',
        'catalog_svc_05',
        'catalog_svc_06',
        'catalog_svc_07',
        'catalog_svc_08',
        'catalog_svc_09',
        'catalog_svc_10',
        'catalog_svc_11',
        'catalog_svc_24',
        'catalog_svc_25',
        'catalog_svc_26',
        'catalog_svc_27',
        'catalog_svc_28',
        'catalog_svc_29',
        'catalog_svc_30',
        'catalog_svc_31',
        'catalog_svc_32',
        'catalog_svc_33',
        'catalog_svc_34',
        'catalog_svc_35',
        'catalog_svc_36',
        'catalog_svc_37',
        'catalog_svc_38',
        'catalog_svc_39',
        'catalog_svc_40',
        'catalog_svc_41',
        'catalog_svc_42',
        'catalog_svc_43',
        'catalog_svc_44',
        'catalog_svc_50',
        'catalog_svc_52',
        'catalog_svc_53',
        'catalog_svc_54',
        'catalog_svc_55',
        'catalog_svc_56',
        'catalog_svc_57',
        'catalog_svc_58',
        'catalog_svc_60',
        'catalog_svc_61',
        'catalog_svc_62',
        'catalog_svc_63',
        'catalog_svc_65',
      ],
      rewardXp: 120,
    ),
    Employee(
      id: 'emp_arch_01',
      fullName: 'Kabir Sethi',
      role: 'Former Barber',
      specialty: 'Classic grooming',
      phone: '+91 90000 44101',
      email: 'kabir.archive@glamora.in',
      isActive: false,
      createdAt: DateTime(2023, 8, 12),
      experienceYears: 7,
      serviceIds: ['catalog_svc_45', 'catalog_svc_46', 'catalog_svc_47'],
      rewardXp: 60,
    ),
    Employee(
      id: 'emp_arch_02',
      fullName: 'Sara Dsouza',
      role: 'Former Nail Artist',
      specialty: 'Gel polish',
      phone: '+91 90000 44102',
      email: 'sara.archive@glamora.in',
      isActive: false,
      createdAt: DateTime(2023, 9, 4),
      experienceYears: 4,
      serviceIds: ['catalog_svc_31', 'catalog_svc_36', 'catalog_svc_37'],
      rewardXp: 45,
    ),
    Employee(
      id: 'emp_arch_03',
      fullName: 'Devika Nair',
      role: 'Former Makeup Artist',
      specialty: 'Party makeup',
      phone: '+91 90000 44103',
      email: 'devika.archive@glamora.in',
      isActive: false,
      createdAt: DateTime(2023, 10, 18),
      experienceYears: 5,
      serviceIds: ['catalog_svc_52', 'catalog_svc_53', 'catalog_svc_54'],
      rewardXp: 90,
    ),
    Employee(
      id: 'emp_arch_04',
      fullName: 'Farah Khan',
      role: 'Former Spa Therapist',
      specialty: 'Relaxation massage',
      phone: '+91 90000 44104',
      email: 'farah.archive@glamora.in',
      isActive: false,
      createdAt: DateTime(2024, 1, 9),
      experienceYears: 6,
      serviceIds: ['catalog_svc_39', 'catalog_svc_41', 'catalog_svc_42'],
      rewardXp: 75,
    ),
    Employee(
      id: 'emp_arch_05',
      fullName: 'Mira Sen',
      role: 'Former Colourist',
      specialty: 'Highlights',
      phone: '+91 90000 44105',
      email: 'mira.archive@glamora.in',
      isActive: false,
      createdAt: DateTime(2024, 2, 6),
      experienceYears: 8,
      serviceIds: ['catalog_svc_19', 'catalog_svc_20', 'catalog_svc_21'],
      rewardXp: 110,
    ),
  ];

  static final List<EmployeeRewardTransaction> employeeRewards = [
    EmployeeRewardTransaction(
      id: 'reward_01',
      employeeId: 'emp_01',
      amount: 180,
      reason: 'Opening balance',
      performedBy: 'admin',
      createdAt: DateTime(2025, 1, 5),
    ),
    EmployeeRewardTransaction(
      id: 'reward_02',
      employeeId: 'emp_02',
      amount: 240,
      reason: 'Opening balance',
      performedBy: 'admin',
      createdAt: DateTime(2025, 1, 5),
    ),
    EmployeeRewardTransaction(
      id: 'reward_03',
      employeeId: 'emp_03',
      amount: 25,
      reason: 'Positive client feedback',
      performedBy: 'admin',
      createdAt: DateTime(2025, 2, 12),
    ),
    EmployeeRewardTransaction(
      id: 'reward_04',
      employeeId: 'emp_03',
      amount: 20,
      reason: 'Facial service upsell',
      performedBy: 'admin',
      createdAt: DateTime(2025, 3, 3),
    ),
    EmployeeRewardTransaction(
      id: 'reward_05',
      employeeId: 'emp_03',
      amount: 30,
      reason: 'Weekend availability support',
      performedBy: 'admin',
      createdAt: DateTime(2025, 4, 18),
    ),
    EmployeeRewardTransaction(
      id: 'reward_06',
      employeeId: 'emp_03',
      amount: 15,
      reason: 'Inventory care check',
      performedBy: 'admin',
      createdAt: DateTime(2025, 5, 9),
    ),
    EmployeeRewardTransaction(
      id: 'reward_07',
      employeeId: 'emp_03',
      amount: 30,
      reason: 'Repeat booking recognition',
      performedBy: 'admin',
      createdAt: DateTime(2025, 6, 14),
    ),
  ];

  static final List<Client> clients = [
    Client(
      id: 'client_01',
      fullName: 'Riya Shetty',
      phone: '+91 98765 00123',
      email: 'riya@example.com',
      notes: 'Prefers softer finishing and longer styling time.',
      createdAt: DateTime(2024, 3, 1),
      lastVisitAt: DateTime(2025, 6, 12),
      loyaltyPoints: 142,
      visitCount: 1,
    ),
    Client(
      id: 'client_02',
      fullName: 'Meher Iyer',
      phone: '+91 98877 44321',
      email: 'meher@example.com',
      notes: 'Loyal VIP client.',
      createdAt: DateTime(2023, 11, 5),
      lastVisitAt: DateTime(2025, 7, 3),
      loyaltyPoints: 310,
      visitCount: 3,
      isVip: true,
    ),
    Client(
      id: 'client_03',
      fullName: 'Aditi Shah',
      phone: '+91 98331 90012',
      email: 'aditi@example.com',
      notes: 'Interested in bridal care packages.',
      createdAt: DateTime(2024, 5, 20),
      lastVisitAt: DateTime(2025, 5, 9),
      loyaltyPoints: 96,
      visitCount: 0,
    ),
    Client(
      id: 'client_04',
      fullName: 'Neha Rao',
      phone: '+91 99999 01010',
      email: 'neha@example.com',
      createdAt: DateTime(2025, 1, 10),
      loyaltyPoints: 24,
      visitCount: 0,
      isArchived: true,
    ),
    Client(
      id: 'client_05',
      fullName: 'Tara Menon',
      phone: '+91 99999 02020',
      createdAt: DateTime(2025, 2, 14),
    ),
  ];

  static final List<Invoice> invoices = [
    Invoice(
      id: 'inv_client_01',
      appointmentId: 'appt_01',
      clientId: 'client_01',
      subtotal: 1800,
      tax: 324,
      total: 2124,
      issuedAt: DateTime(2025, 6, 12),
      isPaid: true,
    ),
    ...List.generate(3, (index) {
      final appointment = appointments[index + 4];
      return Invoice(
        id: 'inv_vip_$index',
        appointmentId: appointment.id,
        clientId: appointment.clientId,
        subtotal: 4200,
        tax: 756,
        total: 4956,
        issuedAt: DateTime(2025, 6, 1 + index, 12),
        isPaid: true,
        invoiceNumber: 'GLM-VIP-${100 + index}',
        clientName: appointment.clientName,
        paymentStatus: PaymentStatus.paid,
        paymentMethod: PaymentMethod.upi,
        amountPaid: 4956,
        balance: 0,
      );
    }),
  ];

  static final List<Service> services = _buildServiceCatalog();

  static List<Service> _buildServiceCatalog() {
    final seeded = <Service>[
      Service(
        id: 'svc_01',
        name: 'Signature Cut & Finish',
        description: 'Precision haircut with premium styling finish.',
        durationMinutes: 60,
        price: 1800,
        category: ServiceCategory.hair,
        isActive: true,
        createdAt: DateTime(2024, 1, 10),
        assignedEmployeeIds: ['emp_01'],
        historicalName: 'Signature Cut & Finish',
        historicalDurationMinutes: 60,
        historicalPrice: 1800,
      ),
      Service(
        id: 'svc_02',
        name: 'Balayage Refresh',
        description: 'Dimensional colour with gloss finish.',
        durationMinutes: 120,
        price: 4200,
        category: ServiceCategory.hair,
        isActive: true,
        createdAt: DateTime(2024, 1, 12),
        assignedEmployeeIds: ['emp_02'],
        historicalName: 'Balayage Refresh',
        historicalDurationMinutes: 120,
        historicalPrice: 4200,
      ),
      Service(
        id: 'svc_03',
        name: 'Glow Facial',
        description: 'Deep hydration and calming treatment.',
        durationMinutes: 45,
        price: 2200,
        category: ServiceCategory.face,
        isActive: true,
        createdAt: DateTime(2024, 2, 2),
        assignedEmployeeIds: ['emp_03'],
        historicalName: 'Glow Facial',
        historicalDurationMinutes: 45,
        historicalPrice: 2200,
      ),
      Service(
        id: 'svc_04',
        name: 'Bridal Styling',
        description: 'Luxury bridal styling for special occasions.',
        durationMinutes: 90,
        price: 6500,
        category: ServiceCategory.events,
        isActive: true,
        createdAt: DateTime(2024, 4, 9),
        assignedEmployeeIds: ['emp_01', 'emp_03'],
        historicalName: 'Bridal Styling',
        historicalDurationMinutes: 90,
        historicalPrice: 6500,
      ),
      Service(
        id: 'svc_05',
        name: 'Express Manicure',
        description: 'Neat, polished hands with a nourishing finish.',
        durationMinutes: 45,
        price: 1200,
        category: ServiceCategory.nails,
        isActive: true,
        createdAt: DateTime(2024, 4, 12),
        assignedEmployeeIds: ['emp_03'],
        historicalName: 'Express Manicure',
        historicalCategory: ServiceCategory.nails,
        historicalDurationMinutes: 45,
        historicalPrice: 1200,
      ),
      Service(
        id: 'svc_06',
        name: 'Wellness Massage',
        description: 'A calming full-body reset with aromatic oils.',
        durationMinutes: 60,
        price: 2800,
        category: ServiceCategory.wellness,
        isActive: true,
        createdAt: DateTime(2024, 5, 4),
        assignedEmployeeIds: ['emp_03'],
        historicalName: 'Wellness Massage',
        historicalCategory: ServiceCategory.wellness,
        historicalDurationMinutes: 60,
        historicalPrice: 2800,
      ),
      Service(
        id: 'svc_07',
        name: 'Precision Beard Grooming',
        description: 'Detailed beard shaping and restorative conditioning.',
        durationMinutes: 30,
        price: 900,
        category: ServiceCategory.grooming,
        isActive: true,
        createdAt: DateTime(2024, 5, 10),
        assignedEmployeeIds: ['emp_01'],
        historicalName: 'Precision Beard Grooming',
        historicalCategory: ServiceCategory.grooming,
        historicalDurationMinutes: 30,
        historicalPrice: 900,
      ),
      Service(
        id: 'svc_08',
        name: 'Soft Glam Make Up',
        description: 'Camera-ready soft glam for celebrations and evenings.',
        durationMinutes: 75,
        price: 3500,
        category: ServiceCategory.makeUp,
        isActive: true,
        createdAt: DateTime(2024, 5, 18),
        assignedEmployeeIds: ['emp_01', 'emp_03'],
        historicalName: 'Soft Glam Make Up',
        historicalCategory: ServiceCategory.makeUp,
        historicalDurationMinutes: 75,
        historicalPrice: 3500,
      ),
      Service(
        id: 'svc_09',
        name: 'Full Leg Waxing',
        description:
            'Comfort-focused waxing with a soothing after-care finish.',
        durationMinutes: 50,
        price: 1600,
        category: ServiceCategory.bodyWaxing,
        isActive: false,
        createdAt: DateTime(2024, 6, 1),
        assignedEmployeeIds: ['emp_03'],
        historicalName: 'Full Leg Waxing',
        historicalCategory: ServiceCategory.bodyWaxing,
        historicalDurationMinutes: 50,
        historicalPrice: 1600,
      ),
      // Extended local/demo catalogue. The numeric price and duration remain
      // available for appointment scheduling; display labels support packages.
      Service(
        id: 'svc_10',
        name: 'Deep Cleansing Facial',
        description:
            'A clarifying facial with gentle exfoliation and hydration.',
        durationMinutes: 60,
        price: 1800,
        category: ServiceCategory.face,
        isActive: true,
        createdAt: DateTime(2024, 6, 5),
        assignedEmployeeIds: ['emp_03'],
      ),
      Service(
        id: 'svc_11',
        name: 'Hydra Glow Facial',
        description: 'A deeply hydrating facial for a fresh, luminous finish.',
        durationMinutes: 75,
        price: 3000,
        category: ServiceCategory.face,
        isActive: true,
        createdAt: DateTime(2024, 6, 6),
        assignedEmployeeIds: ['emp_03'],
      ),
      Service(
        id: 'svc_12',
        name: 'Acne Control Facial',
        description:
            'A calming treatment for congested and blemish-prone skin.',
        durationMinutes: 60,
        price: 2400,
        category: ServiceCategory.face,
        isActive: true,
        createdAt: DateTime(2024, 6, 7),
        assignedEmployeeIds: ['emp_03'],
      ),
      Service(
        id: 'svc_13',
        name: 'Hair Spa',
        description:
            'Nourishing scalp and hair conditioning with a relaxing finish.',
        durationMinutes: 90,
        price: 2200,
        category: ServiceCategory.hair,
        isActive: true,
        createdAt: DateTime(2024, 6, 8),
        assignedEmployeeIds: ['emp_01', 'emp_02'],
      ),
      Service(
        id: 'svc_14',
        name: 'Keratin Treatment',
        description: 'Smoothing treatment for softer, more manageable hair.',
        durationMinutes: 180,
        price: 6500,
        category: ServiceCategory.hair,
        isActive: true,
        createdAt: DateTime(2024, 6, 9),
        assignedEmployeeIds: ['emp_02'],
      ),
      Service(
        id: 'svc_15',
        name: 'Hair Colour',
        description:
            'Professional colour application with a conditioning finish.',
        durationMinutes: 150,
        price: 3800,
        category: ServiceCategory.hair,
        isActive: true,
        createdAt: DateTime(2024, 6, 10),
        assignedEmployeeIds: ['emp_02'],
      ),
      Service(
        id: 'svc_16',
        name: 'Scalp Detox',
        description: 'A refreshing scalp cleanse and restorative treatment.',
        durationMinutes: 45,
        price: 1600,
        category: ServiceCategory.hair,
        isActive: true,
        createdAt: DateTime(2024, 6, 11),
        assignedEmployeeIds: ['emp_01', 'emp_02'],
      ),
      Service(
        id: 'svc_17',
        name: 'Underarm Waxing',
        description: 'Quick, comfortable waxing with soothing after-care.',
        durationMinutes: 20,
        price: 500,
        category: ServiceCategory.bodyWaxing,
        isActive: true,
        createdAt: DateTime(2024, 6, 12),
        assignedEmployeeIds: ['emp_03'],
      ),
      Service(
        id: 'svc_18',
        name: 'Full Arms Waxing',
        description: 'Smooth full-arm waxing with a calming finish.',
        durationMinutes: 35,
        price: 900,
        category: ServiceCategory.bodyWaxing,
        isActive: true,
        createdAt: DateTime(2024, 6, 13),
        assignedEmployeeIds: ['emp_03'],
      ),
      Service(
        id: 'svc_19',
        name: 'Full Body Waxing',
        description: 'A complete waxing service with post-treatment care.',
        durationMinutes: 150,
        price: 4500,
        category: ServiceCategory.bodyWaxing,
        isActive: true,
        createdAt: DateTime(2024, 6, 14),
        assignedEmployeeIds: ['emp_03'],
      ),
      Service(
        id: 'svc_20',
        name: 'Gel Manicure',
        description: 'Long-wear gel colour with neat cuticle care.',
        durationMinutes: 60,
        price: 1800,
        category: ServiceCategory.nails,
        isActive: true,
        createdAt: DateTime(2024, 6, 15),
        assignedEmployeeIds: ['emp_03'],
      ),
      Service(
        id: 'svc_21',
        name: 'Spa Pedicure',
        description: 'Relaxing foot care with exfoliation and polish.',
        durationMinutes: 60,
        price: 1600,
        category: ServiceCategory.nails,
        isActive: true,
        createdAt: DateTime(2024, 6, 16),
        assignedEmployeeIds: ['emp_03'],
      ),
      Service(
        id: 'svc_22',
        name: 'Nail Art',
        description: 'Creative nail detailing tailored to your chosen look.',
        durationMinutes: 45,
        price: 1200,
        category: ServiceCategory.nails,
        isActive: true,
        createdAt: DateTime(2024, 6, 17),
        assignedEmployeeIds: ['emp_03'],
      ),
      Service(
        id: 'svc_23',
        name: 'Swedish Massage',
        description: 'A calming full-body massage using flowing techniques.',
        durationMinutes: 60,
        price: 3000,
        category: ServiceCategory.wellness,
        isActive: true,
        createdAt: DateTime(2024, 6, 18),
        assignedEmployeeIds: ['emp_03'],
      ),
      Service(
        id: 'svc_24',
        name: 'Aromatherapy Massage',
        description: 'A restorative massage with a curated aromatic blend.',
        durationMinutes: 75,
        price: 3400,
        category: ServiceCategory.wellness,
        isActive: true,
        createdAt: DateTime(2024, 6, 19),
        assignedEmployeeIds: ['emp_03'],
      ),
      Service(
        id: 'svc_25',
        name: 'Head & Shoulder Massage',
        description: 'Targeted relief for the head, neck, and shoulders.',
        durationMinutes: 45,
        price: 1800,
        category: ServiceCategory.wellness,
        isActive: true,
        createdAt: DateTime(2024, 6, 20),
        assignedEmployeeIds: ['emp_03'],
      ),
      Service(
        id: 'svc_26',
        name: 'Classic Shave',
        description: 'Traditional close shave with warm towel preparation.',
        durationMinutes: 30,
        price: 700,
        category: ServiceCategory.grooming,
        isActive: true,
        createdAt: DateTime(2024, 6, 21),
        assignedEmployeeIds: ['emp_01'],
      ),
      Service(
        id: 'svc_27',
        name: 'Hair Styling',
        description: 'A polished blow-dry or styling finish for any occasion.',
        durationMinutes: 45,
        price: 1000,
        category: ServiceCategory.grooming,
        isActive: true,
        createdAt: DateTime(2024, 6, 22),
        assignedEmployeeIds: ['emp_01'],
      ),
      Service(
        id: 'svc_28',
        name: 'Brow Threading',
        description: 'Precise brow shaping with a clean, balanced finish.',
        durationMinutes: 20,
        price: 350,
        category: ServiceCategory.grooming,
        isActive: true,
        createdAt: DateTime(2024, 6, 23),
        assignedEmployeeIds: ['emp_01', 'emp_03'],
      ),
      Service(
        id: 'svc_29',
        name: 'HD Makeup',
        description: 'Camera-ready makeup with a refined, long-wear finish.',
        durationMinutes: 120,
        price: 5000,
        category: ServiceCategory.makeUp,
        isActive: true,
        createdAt: DateTime(2024, 6, 24),
        assignedEmployeeIds: ['emp_01', 'emp_03'],
      ),
      Service(
        id: 'svc_30',
        name: 'Party Makeup',
        description: 'A polished makeup look for celebrations and evenings.',
        durationMinutes: 90,
        price: 3500,
        category: ServiceCategory.makeUp,
        isActive: true,
        createdAt: DateTime(2024, 6, 25),
        assignedEmployeeIds: ['emp_01', 'emp_03'],
      ),
      Service(
        id: 'svc_31',
        name: 'Eye Makeup',
        description: 'Defined eye makeup designed to complement your look.',
        durationMinutes: 45,
        price: 1800,
        category: ServiceCategory.makeUp,
        isActive: true,
        createdAt: DateTime(2024, 6, 26),
        assignedEmployeeIds: ['emp_01', 'emp_03'],
      ),
      Service(
        id: 'svc_32',
        name: 'Engagement Makeup',
        description: 'Softly elevated makeup for engagement celebrations.',
        durationMinutes: 150,
        price: 7000,
        category: ServiceCategory.events,
        isActive: true,
        createdAt: DateTime(2024, 6, 27),
        assignedEmployeeIds: ['emp_01', 'emp_03'],
      ),
      Service(
        id: 'svc_33',
        name: 'Pre-Bridal Package',
        description:
            'A flexible multi-session package; final price depends on selected sessions.',
        durationMinutes: 480,
        price: 15000,
        priceLabel: 'Rs 10,000–20,000',
        durationLabel: 'Multiple sessions',
        category: ServiceCategory.events,
        isActive: true,
        createdAt: DateTime(2024, 6, 28),
        assignedEmployeeIds: ['emp_01', 'emp_03'],
      ),
      Service(
        id: 'svc_34',
        name: 'Reception Styling',
        description: 'Complete hair and makeup styling for reception events.',
        durationMinutes: 90,
        price: 4500,
        category: ServiceCategory.events,
        isActive: true,
        createdAt: DateTime(2024, 6, 29),
        assignedEmployeeIds: ['emp_01', 'emp_03'],
      ),
    ];
    const originalIds = {
      'svc_01',
      'svc_02',
      'svc_03',
      'svc_04',
      'svc_05',
      'svc_06',
      'svc_07',
      'svc_08',
      'svc_09',
    };
    return [
      ...seeded.where((service) => originalIds.contains(service.id)),
      ..._requiredServiceCatalog,
    ];
  }

  static final Set<String> seedClientIds = clients
      .map((client) => client.id)
      .toSet();

  static final List<Appointment> appointments = [
    Appointment(
      id: 'appt_01',
      clientId: 'client_01',
      clientName: 'Riya Shetty',
      employeeId: 'emp_01',
      employeeName: 'Aarohi Mehta',
      startAt: DateTime.now().add(const Duration(days: 0, hours: 10)),
      endAt: DateTime.now().add(
        const Duration(days: 0, hours: 11, minutes: 15),
      ),
      status: AppointmentStatus.confirmed,
      services: const [
        AppointmentService(
          id: 'aps_01',
          serviceId: 'svc_01',
          serviceName: 'Signature Cut & Finish',
          durationMinutes: 60,
          price: 1800,
          employeeId: 'emp_01',
          employeeName: 'Aarohi Mehta',
          historicalServiceName: 'Signature Cut & Finish',
          historicalDurationMinutes: 60,
          historicalPrice: 1800,
        ),
      ],
      notes: 'Prefers clean layered finish.',
      source: 'App',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Appointment(
      id: 'appt_02',
      clientId: 'client_02',
      clientName: 'Meher Iyer',
      employeeId: 'emp_02',
      employeeName: 'Ishaan Verma',
      startAt: DateTime.now().add(const Duration(days: 1, hours: 14)),
      endAt: DateTime.now().add(const Duration(days: 1, hours: 16)),
      status: AppointmentStatus.pending,
      services: const [
        AppointmentService(
          id: 'aps_02',
          serviceId: 'svc_02',
          serviceName: 'Balayage Refresh',
          durationMinutes: 120,
          price: 4200,
          employeeId: 'emp_02',
          employeeName: 'Ishaan Verma',
          historicalServiceName: 'Balayage Refresh',
          historicalDurationMinutes: 120,
          historicalPrice: 4200,
        ),
      ],
      notes: 'Follow-up colour touch-up.',
      source: 'Reception',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Appointment(
      id: 'appt_cancelled',
      clientId: 'client_03',
      clientName: 'Aditi Shah',
      employeeId: 'emp_03',
      employeeName: 'Naina Kapoor',
      startAt: DateTime(2025, 8, 10, 11),
      endAt: DateTime(2025, 8, 10, 11, 45),
      status: AppointmentStatus.cancelled,
      services: const [
        AppointmentService(
          id: 'aps_cancelled',
          serviceId: 'svc_03',
          serviceName: 'Glow Facial',
          durationMinutes: 45,
          price: 2200,
          employeeId: 'emp_03',
          employeeName: 'Naina Kapoor',
          historicalServiceName: 'Glow Facial',
          historicalCategory: ServiceCategory.face,
          historicalDurationMinutes: 45,
          historicalPrice: 2200,
        ),
      ],
      cancellationReason: 'Client requested a different date.',
      cancelledBy: 'demo',
      cancelledAt: DateTime(2025, 8, 9, 16),
      createdAt: DateTime(2025, 8, 1),
    ),
    Appointment(
      id: 'appt_no_show',
      clientId: 'client_01',
      clientName: 'Riya Shetty',
      employeeId: 'emp_01',
      employeeName: 'Aarohi Mehta',
      startAt: DateTime(2025, 8, 15, 15),
      endAt: DateTime(2025, 8, 15, 16),
      status: AppointmentStatus.noShow,
      services: const [
        AppointmentService(
          id: 'aps_no_show',
          serviceId: 'svc_01',
          serviceName: 'Signature Cut & Finish',
          durationMinutes: 60,
          price: 1800,
          employeeId: 'emp_01',
          employeeName: 'Aarohi Mehta',
          historicalServiceName: 'Signature Cut & Finish',
          historicalCategory: ServiceCategory.hair,
          historicalDurationMinutes: 60,
          historicalPrice: 1800,
        ),
      ],
      createdAt: DateTime(2025, 8, 5),
    ),
    for (var index = 0; index < 3; index++)
      Appointment(
        id: 'appt_vip_$index',
        clientId: 'client_02',
        clientName: 'Meher Iyer',
        employeeId: 'emp_02',
        employeeName: 'Ishaan Verma',
        startAt: DateTime(2025, 6, 1 + index, 10),
        endAt: DateTime(2025, 6, 1 + index, 12),
        status: AppointmentStatus.completed,
        services: const [
          AppointmentService(
            id: 'aps_vip',
            serviceId: 'svc_02',
            serviceName: 'Balayage Refresh',
            durationMinutes: 120,
            price: 4200,
            employeeId: 'emp_02',
            employeeName: 'Ishaan Verma',
            historicalServiceName: 'Balayage Refresh',
            historicalDurationMinutes: 120,
            historicalPrice: 4200,
          ),
        ],
        createdAt: DateTime(2025, 5, 20),
      ),
    ...List.generate(5, (index) {
      final service = services[index + 2];
      final employeeId = service.assignedEmployeeIds.first;
      final employee = employees.firstWhere((item) => item.id == employeeId);
      final client = clients[index % 3];
      final startAt = DateTime(2025, 7, 10 + index, 10 + index);
      final statuses = [
        AppointmentStatus.confirmed,
        AppointmentStatus.pending,
        AppointmentStatus.completed,
        AppointmentStatus.confirmed,
        AppointmentStatus.completed,
      ];
      return Appointment(
        id: 'appt_demo_${index + 1}',
        clientId: client.id,
        clientName: client.fullName,
        employeeId: employee.id,
        employeeName: employee.fullName,
        startAt: startAt,
        endAt: startAt.add(Duration(minutes: service.durationMinutes)),
        status: statuses[index],
        services: [
          AppointmentService(
            id: 'aps_demo_${index + 1}',
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
        ],
        source: 'Demo sample',
        createdAt: DateTime(2025, 7, 1),
      );
    }),
  ];

  static final List<Payment> payments = [
    Payment(
      id: 'pay_01',
      appointmentId: 'appt_01',
      invoiceId: 'inv_client_01',
      clientId: 'client_01',
      amount: 1800,
      method: PaymentMethod.card,
      status: PaymentStatus.paid,
      createdAt: DateTime.now().subtract(const Duration(hours: 7)),
      receiptNumber: 'RCPT-1018',
    ),
    Payment(
      id: 'pay_02',
      appointmentId: 'appt_02',
      clientId: 'client_02',
      amount: 4200,
      method: PaymentMethod.upi,
      status: PaymentStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      receiptNumber: 'RCPT-1020',
    ),
    for (var index = 0; index < 3; index++)
      Payment(
        id: 'pay_vip_$index',
        appointmentId: 'appt_vip_$index',
        invoiceId: 'inv_vip_$index',
        clientId: 'client_02',
        amount: 4956,
        method: PaymentMethod.upi,
        status: PaymentStatus.paid,
        createdAt: DateTime(2025, 6, 1 + index, 12),
        receiptNumber: 'RCPT-VIP-$index',
      ),
  ];

  static final List<InventoryProduct> inventoryProducts = [
    InventoryProduct(
      id: 'inv_01',
      name: 'Daily Hair Serum',
      category: 'Hair Care',
      quantityOnHand: 18,
      unitPrice: 950,
      updatedAt: DateTime(2025, 7, 20),
      sku: 'HS-1001',
      lowStockThreshold: 6,
    ),
    InventoryProduct(
      id: 'inv_02',
      name: 'Luxury Moisturiser',
      category: 'Skin Care',
      quantityOnHand: 12,
      unitPrice: 1400,
      updatedAt: DateTime(2025, 7, 18),
      sku: 'SC-2201',
      lowStockThreshold: 12,
    ),
    InventoryProduct(
      id: 'inv_03',
      name: 'Stone Massage Oil',
      category: 'Massage',
      quantityOnHand: 9,
      unitPrice: 1100,
      updatedAt: DateTime(2025, 7, 17),
      sku: 'MO-3102',
      lowStockThreshold: 10,
    ),
    InventoryProduct(
      id: 'inv_arch_01',
      name: 'Rose Clay Mask',
      category: 'Skin Care',
      quantityOnHand: 0,
      unitPrice: 850,
      updatedAt: DateTime(2025, 4, 5),
      sku: 'SC-OLD-01',
      lowStockThreshold: 5,
      isActive: false,
    ),
    InventoryProduct(
      id: 'inv_arch_02',
      name: 'Citrus Cuticle Oil',
      category: 'Nail Care',
      quantityOnHand: 0,
      unitPrice: 420,
      updatedAt: DateTime(2025, 4, 12),
      sku: 'NC-OLD-02',
      lowStockThreshold: 4,
      isActive: false,
    ),
    InventoryProduct(
      id: 'inv_arch_03',
      name: 'Keratin Trial Sachets',
      category: 'Hair Care',
      quantityOnHand: 0,
      unitPrice: 300,
      updatedAt: DateTime(2025, 5, 2),
      sku: 'HC-OLD-03',
      lowStockThreshold: 10,
      isActive: false,
    ),
    InventoryProduct(
      id: 'inv_arch_04',
      name: 'Lavender Foot Soak',
      category: 'Wellness',
      quantityOnHand: 0,
      unitPrice: 650,
      updatedAt: DateTime(2025, 5, 16),
      sku: 'WL-OLD-04',
      lowStockThreshold: 6,
      isActive: false,
    ),
    InventoryProduct(
      id: 'inv_arch_05',
      name: 'Matte Styling Wax',
      category: 'Grooming',
      quantityOnHand: 0,
      unitPrice: 750,
      updatedAt: DateTime(2025, 6, 1),
      sku: 'GR-OLD-05',
      lowStockThreshold: 5,
      isActive: false,
    ),
  ];

  static final List<InventoryTransaction> inventoryTransactions = [
    InventoryTransaction(
      id: 'stock_01',
      productId: 'inv_01',
      productName: 'Daily Hair Serum',
      type: InventoryTransactionType.stockIn,
      quantity: 18,
      previousQuantity: 0,
      newQuantity: 18,
      reason: 'Opening stock',
      performedBy: 'admin',
      createdAt: DateTime(2025, 7, 20),
    ),
    InventoryTransaction(
      id: 'stock_02',
      productId: 'inv_02',
      productName: 'Luxury Moisturiser',
      type: InventoryTransactionType.stockIn,
      quantity: 12,
      previousQuantity: 0,
      newQuantity: 12,
      reason: 'Opening stock',
      performedBy: 'admin',
      createdAt: DateTime(2025, 7, 18),
    ),
    InventoryTransaction(
      id: 'stock_03',
      productId: 'inv_03',
      productName: 'Stone Massage Oil',
      type: InventoryTransactionType.stockIn,
      quantity: 14,
      previousQuantity: 0,
      newQuantity: 14,
      reason: 'Opening stock',
      performedBy: 'admin',
      createdAt: DateTime(2025, 7, 10),
    ),
    InventoryTransaction(
      id: 'stock_04',
      productId: 'inv_03',
      productName: 'Stone Massage Oil',
      type: InventoryTransactionType.stockOut,
      quantity: 3,
      previousQuantity: 14,
      newQuantity: 11,
      reason: 'Wellness massage appointments',
      performedBy: 'admin',
      createdAt: DateTime(2025, 7, 12),
    ),
    InventoryTransaction(
      id: 'stock_05',
      productId: 'inv_03',
      productName: 'Stone Massage Oil',
      type: InventoryTransactionType.stockIn,
      quantity: 6,
      previousQuantity: 11,
      newQuantity: 17,
      reason: 'Supplier restock',
      performedBy: 'admin',
      createdAt: DateTime(2025, 7, 14),
    ),
    InventoryTransaction(
      id: 'stock_06',
      productId: 'inv_03',
      productName: 'Stone Massage Oil',
      type: InventoryTransactionType.stockOut,
      quantity: 5,
      previousQuantity: 17,
      newQuantity: 12,
      reason: 'Body spa service usage',
      performedBy: 'admin',
      createdAt: DateTime(2025, 7, 15),
    ),
    InventoryTransaction(
      id: 'stock_07',
      productId: 'inv_03',
      productName: 'Stone Massage Oil',
      type: InventoryTransactionType.adjustment,
      quantity: -3,
      previousQuantity: 12,
      newQuantity: 9,
      reason: 'Bottle count reconciliation',
      performedBy: 'admin',
      createdAt: DateTime(2025, 7, 17),
    ),
    InventoryTransaction(
      id: 'stock_08',
      productId: 'inv_arch_01',
      productName: 'Rose Clay Mask',
      type: InventoryTransactionType.stockOut,
      quantity: 6,
      previousQuantity: 6,
      newQuantity: 0,
      reason: 'Product discontinued',
      performedBy: 'admin',
      createdAt: DateTime(2025, 4, 5),
    ),
    InventoryTransaction(
      id: 'stock_09',
      productId: 'inv_arch_02',
      productName: 'Citrus Cuticle Oil',
      type: InventoryTransactionType.stockOut,
      quantity: 4,
      previousQuantity: 4,
      newQuantity: 0,
      reason: 'Replaced by new nail care line',
      performedBy: 'admin',
      createdAt: DateTime(2025, 4, 12),
    ),
    InventoryTransaction(
      id: 'stock_10',
      productId: 'inv_arch_03',
      productName: 'Keratin Trial Sachets',
      type: InventoryTransactionType.stockOut,
      quantity: 18,
      previousQuantity: 18,
      newQuantity: 0,
      reason: 'Trial kit completed',
      performedBy: 'admin',
      createdAt: DateTime(2025, 5, 2),
    ),
    InventoryTransaction(
      id: 'stock_11',
      productId: 'inv_arch_04',
      productName: 'Lavender Foot Soak',
      type: InventoryTransactionType.stockOut,
      quantity: 8,
      previousQuantity: 8,
      newQuantity: 0,
      reason: 'Spa pedicure formula retired',
      performedBy: 'admin',
      createdAt: DateTime(2025, 5, 16),
    ),
    InventoryTransaction(
      id: 'stock_12',
      productId: 'inv_arch_05',
      productName: 'Matte Styling Wax',
      type: InventoryTransactionType.stockOut,
      quantity: 5,
      previousQuantity: 5,
      newQuantity: 0,
      reason: 'Old grooming stock cleared',
      performedBy: 'admin',
      createdAt: DateTime(2025, 6, 1),
    ),
  ];
}
