import '../../../models/salon_models.dart';

class ClientRules {
  const ClientRules._();

  static bool isVipFromHistory(ClientHistory history) {
    final completedPaidAppointments = history.appointments.where(
      (appointment) =>
          appointment.status == AppointmentStatus.completed &&
          history.payments.any(
            (payment) =>
                payment.appointmentId == appointment.id &&
                payment.status == PaymentStatus.paid,
          ),
    );
    return completedPaidAppointments.length >= 3;
  }

  static int completedPaidVisitCount(ClientHistory history) {
    return history.appointments
        .where(
          (appointment) =>
              appointment.status == AppointmentStatus.completed &&
              history.payments.any(
                (payment) =>
                    payment.appointmentId == appointment.id &&
                    payment.status == PaymentStatus.paid,
              ),
        )
        .length;
  }
}
