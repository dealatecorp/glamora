import 'package:flutter/material.dart';
import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/theme/app_radius.dart';
import 'package:saloon_application/core/theme/app_text_styles.dart';
import 'package:saloon_application/models/salon_models.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.appointmentStatus,
    this.paymentStatus,
    this.showSuccessDot = false,
  });

  final String label;
  final Color? color;
  final Color? textColor;
  final AppointmentStatus? appointmentStatus;
  final PaymentStatus? paymentStatus;
  final bool showSuccessDot;

  Color? get _statusDotColor {
    final status = appointmentStatus;
    if (status != null) return AppointmentStatusDot(status: status).color;
    final payment = paymentStatus;
    if (payment != null) return PaymentStatusDot(status: payment).color;
    return showSuccessDot ? AppColors.success : null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_statusDotColor != null) ...[
            _StatusDot(color: _statusDotColor!),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: textColor ?? AppColors.espresso,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AppointmentStatusDot extends StatelessWidget {
  const AppointmentStatusDot({super.key, required this.status, this.size = 6});

  final AppointmentStatus status;
  final double size;

  Color? get color {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppColors.success;
      case AppointmentStatus.pending:
        return AppColors.warning;
      case AppointmentStatus.cancelled:
        return AppColors.error;
      case AppointmentStatus.completed:
        return AppColors.success;
      case AppointmentStatus.checkedIn:
      case AppointmentStatus.noShow:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = color;
    if (dotColor == null) return const SizedBox.shrink();
    return _StatusDot(color: dotColor, size: size);
  }
}

class PaymentStatusDot extends StatelessWidget {
  const PaymentStatusDot({super.key, required this.status, this.size = 6});

  final PaymentStatus status;
  final double size;

  Color get color {
    switch (status) {
      case PaymentStatus.paid:
        return AppColors.success;
      case PaymentStatus.pending:
      case PaymentStatus.authorized:
        return AppColors.warning;
      case PaymentStatus.failed:
        return AppColors.error;
      case PaymentStatus.refunded:
        return AppColors.mutedTaupe;
    }
  }

  @override
  Widget build(BuildContext context) => _StatusDot(color: color, size: size);
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, this.size = 6});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
