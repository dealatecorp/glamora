import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/repositories.dart';
import '../../../features/auth/models/auth_session.dart';
import '../../../models/salon_models.dart';

class CustomerQrScreen extends StatefulWidget {
  const CustomerQrScreen({
    super.key,
    required this.repository,
    required this.session,
  });

  final SettingsRepository repository;
  final AuthSession session;

  @override
  State<CustomerQrScreen> createState() => _CustomerQrScreenState();
}

class _CustomerQrScreenState extends State<CustomerQrScreen> {
  late Future<ApplicationSettings> _settingsFuture;
  bool _saving = false;

  bool get _isAdmin => widget.session.isAdmin;

  @override
  void initState() {
    super.initState();
    _settingsFuture = widget.repository.getApplicationSettings();
  }

  Future<void> _configure(ApplicationSettings settings) async {
    if (!_isAdmin || _saving) return;
    final controller = TextEditingController(text: settings.customerBookingUrl);
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer QR destination'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(labelText: 'Booking website URL'),
            validator: (value) {
              final uri = Uri.tryParse(value?.trim() ?? '');
              if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                return 'Enter a valid website URL.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;

    setState(() => _saving = true);
    try {
      await widget.repository.updateApplicationSettings(
        ApplicationSettings(
          defaultAppointmentDuration: settings.defaultAppointmentDuration,
          reminderHours: settings.reminderHours,
          notificationsEnabled: settings.notificationsEnabled,
          customerBookingUrl: value,
        ),
      );
      if (!mounted) return;
      setState(() {
        _settingsFuture = widget.repository.getApplicationSettings();
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer QR destination saved.')),
      );
    } on RepositoryException catch (exception) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.warmIvory,
    appBar: AppBar(title: const Text('Customer QR')),
    body: SafeArea(
      child: FutureBuilder<ApplicationSettings>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final settings = snapshot.data;
          if (snapshot.hasError || settings == null) {
            return const Center(child: Text('Unable to load customer QR.'));
          }
          final destination = settings.customerBookingUrl;
          final qrUrl =
              'https://api.qrserver.com/v1/create-qr-code/?size=260x260&data=${Uri.encodeComponent(destination)}';
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text('Customer booking QR', style: AppTextStyles.displaySmall),
              const SizedBox(height: 6),
              Text(
                'Customers can scan this QR to open Glamora online booking.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppColors.champagneGold,
                      size: 42,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(12),
                      child: Image.network(
                        qrUrl,
                        width: 260,
                        height: 260,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 260,
                          height: 260,
                          child: Center(child: Text('QR unavailable')),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(destination, style: AppTextStyles.bodySmall),
                  ],
                ),
              ),
              if (_isAdmin) ...[
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Configure QR destination',
                  isLoading: _saving,
                  disabled: _saving,
                  onPressed: () => _configure(settings),
                ),
              ],
            ],
          );
        },
      ),
    ),
  );
}
