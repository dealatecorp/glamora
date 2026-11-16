import 'package:flutter/material.dart';
import 'package:saloon_application/core/theme/app_colors.dart';
import 'package:saloon_application/core/theme/app_text_styles.dart';
import 'package:saloon_application/core/widgets/app_card.dart';
import 'package:saloon_application/core/widgets/section_header.dart';
import 'package:saloon_application/features/auth/models/auth_session.dart';
import 'package:saloon_application/features/auth/models/auth_role.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.session,
    required this.onLogout,
    this.onOpenPayments,
    this.onOpenEmployees,
    this.onOpenOwnEmployee,
    this.onOpenInventory,
    this.onOpenRevenue,
    this.onOpenReports,
    this.onOpenServices,
    this.onOpenBusinessProfile,
    this.onOpenBusinessHours,
    this.onOpenBreaks,
    this.onOpenApplicationSettings,
    this.onOpenCustomerQr,
  });

  final AuthSession session;
  final VoidCallback onLogout;
  final VoidCallback? onOpenPayments;
  final VoidCallback? onOpenEmployees;
  final VoidCallback? onOpenOwnEmployee;
  final VoidCallback? onOpenInventory;
  final VoidCallback? onOpenRevenue;
  final VoidCallback? onOpenReports;
  final VoidCallback? onOpenServices;
  final VoidCallback? onOpenBusinessProfile;
  final VoidCallback? onOpenBusinessHours;
  final VoidCallback? onOpenBreaks;
  final VoidCallback? onOpenApplicationSettings;
  final VoidCallback? onOpenCustomerQr;

  @override
  Widget build(BuildContext context) {
    final sections = <_MoreSection>[
      if (session.isAdmin)
        const _MoreSection('Management', [
          _MoreItem('Employees', Icons.people_alt_rounded, 'Team management'),
          _MoreItem(
            'Services Management',
            Icons.cut_rounded,
            'Manage your menu',
          ),
        ]),
      if (session.isAdmin)
        const _MoreSection('Finance', [
          _MoreItem('Payments', Icons.payment_rounded, 'Payment activity'),
          _MoreItem(
            'Revenue & Earnings',
            Icons.bar_chart_rounded,
            'Admin overview',
          ),
          _MoreItem('Reports', Icons.analytics_rounded, 'Studio reporting'),
        ]),
      const _MoreSection('Inventory', [
        _MoreItem(
          'Salon Products / Inventory',
          Icons.inventory_2_rounded,
          'Stock and supplies',
        ),
      ]),
      const _MoreSection('Studio', [
        _MoreItem(
          'Business Profile',
          Icons.storefront_rounded,
          'Salon details',
        ),
        _MoreItem('Business Hours', Icons.access_time_rounded, 'Opening hours'),
        _MoreItem('Breaks', Icons.free_breakfast_rounded, 'Team availability'),
        _MoreItem(
          'Application Settings',
          Icons.settings_rounded,
          'App preferences',
        ),
        _MoreItem(
          'Customer QR',
          Icons.qr_code_2_rounded,
          'Customer booking access',
        ),
      ]),
      _MoreSection('Account', [
        _MoreItem('Profile', Icons.person_rounded, 'Account identity'),
        _MoreItem('Logout', Icons.logout_rounded, 'Sign out of this device'),
      ]),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Operations hub', style: AppTextStyles.displaySmall),
          const SizedBox(height: 6),
          Text(
            '${session.displayName} · ${session.role.label}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 20),
          ...sections.expand(
            (section) => [
              SectionHeader(title: section.title),
              const SizedBox(height: 10),
              AppCard(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: section.items
                      .map((item) => _itemTile(context, item))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemTile(BuildContext context, _MoreItem item) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        minTileHeight: 60,
        leading: Icon(item.icon, color: AppColors.champagneGold),
        title: Text(item.title, style: AppTextStyles.titleMedium),
        subtitle: Text(item.subtitle, style: AppTextStyles.bodySmall),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.mutedTaupe,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        onTap: () {
          if (item.title == 'Logout') {
            _confirmLogout(context);
          } else if (item.title == 'Payments' && onOpenPayments != null) {
            onOpenPayments!();
          } else if (item.title == 'Employees' && onOpenEmployees != null) {
            onOpenEmployees!();
          } else if (item.title == 'Profile' &&
              session.isEmployee &&
              onOpenOwnEmployee != null) {
            onOpenOwnEmployee!();
          } else if (item.title == 'Salon Products / Inventory' &&
              onOpenInventory != null) {
            onOpenInventory!();
          } else if (item.title == 'Revenue & Earnings' &&
              onOpenRevenue != null) {
            onOpenRevenue!();
          } else if (item.title == 'Reports' && onOpenReports != null) {
            onOpenReports!();
          } else if (item.title == 'Services Management' &&
              onOpenServices != null) {
            onOpenServices!();
          } else if (item.title == 'Business Profile' &&
              onOpenBusinessProfile != null) {
            onOpenBusinessProfile!();
          } else if (item.title == 'Business Hours' &&
              onOpenBusinessHours != null) {
            onOpenBusinessHours!();
          } else if (item.title == 'Breaks' && onOpenBreaks != null) {
            onOpenBreaks!();
          } else if (item.title == 'Application Settings' &&
              onOpenApplicationSettings != null) {
            onOpenApplicationSettings!();
          } else if (item.title == 'Customer QR' &&
              onOpenCustomerQr != null) {
            onOpenCustomerQr!();
          } else {
            _showDestination(context, item.title);
          }
        },
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Your current salon session will be cleared from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) onLogout();
  }

  void _showDestination(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: title == 'Profile'
            ? Text(
                '${session.displayName}\n${session.role.label}\n${session.email ?? session.employeeId ?? 'Salon account'}',
              )
            : const Text(
                'This destination will be available in a later module.',
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MoreSection {
  const _MoreSection(this.title, this.items);
  final String title;
  final List<_MoreItem> items;
}

class _MoreItem {
  const _MoreItem(this.title, this.icon, this.subtitle);
  final String title;
  final IconData icon;
  final String subtitle;
}
