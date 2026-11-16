import 'package:flutter_test/flutter_test.dart';
import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/widgets/status_pill.dart';
import 'package:saloon_application/models/salon_models.dart';

void main() {
  test('appointment status dots use the canonical colors', () {
    expect(
      const AppointmentStatusDot(status: AppointmentStatus.confirmed).color,
      AppColors.success,
    );
    expect(
      const AppointmentStatusDot(status: AppointmentStatus.pending).color,
      AppColors.warning,
    );
    expect(
      const AppointmentStatusDot(status: AppointmentStatus.cancelled).color,
      AppColors.error,
    );
  });

  test('completed uses green while no-show remains without a status dot', () {
    expect(
      const AppointmentStatusDot(status: AppointmentStatus.completed).color,
      AppColors.success,
    );
    expect(
      const AppointmentStatusDot(status: AppointmentStatus.noShow).color,
      isNull,
    );
  });

  test('payment status dots use the canonical colors', () {
    expect(
      const PaymentStatusDot(status: PaymentStatus.paid).color,
      AppColors.success,
    );
    expect(
      const PaymentStatusDot(status: PaymentStatus.pending).color,
      AppColors.warning,
    );
    expect(
      const PaymentStatusDot(status: PaymentStatus.failed).color,
      AppColors.error,
    );
    expect(
      const PaymentStatusDot(status: PaymentStatus.refunded).color,
      AppColors.mutedTaupe,
    );
  });
}
