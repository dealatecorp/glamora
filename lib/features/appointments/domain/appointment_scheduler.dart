import '../../../models/salon_models.dart';

class AppointmentDraftService {
  const AppointmentDraftService({
    required this.service,
    required this.employeeId,
    required this.employeeName,
  });

  final Service service;
  final String employeeId;
  final String employeeName;
}

class AvailabilityResult {
  const AvailabilityResult.available() : reason = null;
  const AvailabilityResult.unavailable(this.reason);

  final String? reason;
  bool get isAvailable => reason == null;
}

class AppointmentScheduler {
  const AppointmentScheduler._();

  static const openingHour = 9;
  static const closingHour = 18;
  static const breakStartHour = 13;
  static const breakEndHour = 14;
  static const slotMinutes = 15;

  static int totalDuration(Iterable<AppointmentDraftService> services) =>
      services.fold(0, (total, item) => total + item.service.durationMinutes);

  static DateTime endAt(
    DateTime startAt,
    Iterable<AppointmentDraftService> services,
  ) => startAt.add(Duration(minutes: totalDuration(services)));

  static AvailabilityResult checkAvailability({
    required DateTime startAt,
    required Iterable<AppointmentDraftService> services,
    required List<Appointment> appointments,
    String? excludingAppointmentId,
    List<BusinessHours>? businessHours,
    List<SalonBreak>? salonBreaks,
  }) {
    final draftServices = services.toList();
    if (draftServices.isEmpty) {
      return const AvailabilityResult.unavailable(
        'Select at least one service.',
      );
    }
    final endAt = AppointmentScheduler.endAt(startAt, draftServices);
    final day = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'][startAt.weekday - 1];
    final configured = businessHours?.where((item) => item.dayName == day).cast<BusinessHours?>().firstOrNull;
    if (configured?.isClosed == true) return const AvailabilityResult.unavailable('The salon is closed on this day.');
    int hour(String value) => int.tryParse(value.split(':').first) ?? openingHour;
    final opening = DateTime(
      startAt.year,
      startAt.month,
      startAt.day,
      configured == null ? openingHour : hour(configured.openTime),
    );
    final closing = DateTime(
      startAt.year,
      startAt.month,
      startAt.day,
      configured == null ? closingHour : hour(configured.closeTime),
    );
    final breakStart = DateTime(
      startAt.year,
      startAt.month,
      startAt.day,
      breakStartHour,
    );
    final breakEnd = DateTime(
      startAt.year,
      startAt.month,
      startAt.day,
      breakEndHour,
    );
    if (startAt.isBefore(opening) || endAt.isAfter(closing)) {
      return const AvailabilityResult.unavailable(
        'Appointment must be within salon hours.',
      );
    }
    final configuredBreaks = salonBreaks?.where((item) => item.date.year == startAt.year && item.date.month == startAt.month && item.date.day == startAt.day) ?? const <SalonBreak>[];
    if (startAt.isBefore(breakEnd) && endAt.isAfter(breakStart)) {
      return const AvailabilityResult.unavailable(
        'Appointment overlaps the salon break.',
      );
    }
    for (final item in configuredBreaks) {
      final parts = item.startTime.split(':'); final endParts = item.endTime.split(':');
      final from = DateTime(startAt.year, startAt.month, startAt.day, int.parse(parts[0]), int.parse(parts[1]));
      final until = DateTime(startAt.year, startAt.month, startAt.day, int.parse(endParts[0]), int.parse(endParts[1]));
      if (startAt.isBefore(until) && endAt.isAfter(from)) return const AvailabilityResult.unavailable('Appointment overlaps a salon break.');
    }
    for (final item in draftServices) {
      if (!item.service.assignedEmployeeIds.contains(item.employeeId)) {
        return AvailabilityResult.unavailable(
          '${item.service.name} is not assigned to ${item.employeeName}.',
        );
      }
    }
    for (final appointment in appointments) {
      if (appointment.id == excludingAppointmentId ||
          appointment.status == AppointmentStatus.cancelled ||
          appointment.status == AppointmentStatus.noShow) {
        continue;
      }
      for (final existingService in appointment.services) {
        if (existingService.employeeId == null) continue;
        for (final draft in draftServices) {
          if (draft.employeeId == existingService.employeeId &&
              startAt.isBefore(appointment.endAt) &&
              endAt.isAfter(appointment.startAt)) {
            return AvailabilityResult.unavailable(
              '${draft.employeeName} is already assigned during this time.',
            );
          }
        }
      }
    }
    return const AvailabilityResult.available();
  }

  static List<DateTime> availableSlots({
    required DateTime date,
    required Iterable<AppointmentDraftService> services,
    required List<Appointment> appointments,
    List<BusinessHours>? businessHours,
    List<SalonBreak>? salonBreaks,
  }) {
    final slots = <DateTime>[];
    var slot = DateTime(date.year, date.month, date.day, openingHour);
    final closing = DateTime(date.year, date.month, date.day, closingHour);
    while (slot.isBefore(closing)) {
      final result = checkAvailability(
        startAt: slot,
        services: services,
        appointments: appointments,
        businessHours: businessHours,
        salonBreaks: salonBreaks,
      );
      if (result.isAvailable) slots.add(slot);
      slot = slot.add(const Duration(minutes: slotMinutes));
    }
    return slots;
  }
}
