import 'package:flutter/material.dart';
import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/theme/app_radius.dart';
import 'package:saloon_application/core/theme/app_text_styles.dart';
import 'package:saloon_application/core/widgets/app_card.dart';
import 'package:saloon_application/core/widgets/primary_button.dart';
import 'package:saloon_application/core/widgets/section_header.dart';
import 'package:saloon_application/core/widgets/status_pill.dart';
import 'package:saloon_application/data/repositories/repositories.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = DemoData.appointments;
    final profile = DemoData.businessProfile;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welcome back', style: AppTextStyles.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          profile.salonName,
                          style: AppTextStyles.displaySmall,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(AppRadius.large),
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.espresso,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.champagneGold,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profile.address,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text('Today’s rhythm', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      '${appointments.length} appointments scheduled',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(label: 'Open salon board', onPressed: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Quick actions'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionTile(
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'New client',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionTile(
                      icon: Icons.schedule_rounded,
                      label: 'Book visit',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionHeader(title: 'Upcoming', action: 'View all'),
              const SizedBox(height: 14),
              ...appointments
                  .take(2)
                  .map(
                    (appointment) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    appointment.clientName,
                                    style: AppTextStyles.titleLarge,
                                  ),
                                ),
                                StatusPill(
                                  label: appointment.status.name,
                                  color: AppColors.cream,
                                  appointmentStatus: appointment.status,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${appointment.startAt.hour}:${appointment.startAt.minute.toString().padLeft(2, '0')} - ${appointment.endAt.hour}:${appointment.endAt.minute.toString().padLeft(2, '0')}',
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              appointment.services
                                  .map((s) => s.serviceName)
                                  .join(', '),
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              const SizedBox(height: 24),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Salon snapshot', style: AppTextStyles.titleLarge),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(label: 'Clients', value: '245'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(label: 'Revenue', value: '₹28.4k'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricTile(label: 'Bookings', value: '18'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricTile(label: 'Loyalty', value: '96%'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: Icon(icon, color: AppColors.champagneGold),
          ),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.titleMedium),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.headlineMedium),
        ],
      ),
    );
  }
}
