import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../features/auth/models/auth_role.dart';
import '../../../features/auth/models/auth_session.dart';
import '../../../models/salon_models.dart';
import 'service_form_screen.dart';
import '../widgets/category_video_background.dart';

class ServiceDetailsScreen extends StatefulWidget {
  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
    required this.repository,
    required this.session,
  });

  final String serviceId;
  final ServiceRepository repository;
  final AuthSession? session;

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  Service? _service;
  List<Employee> _employees = [];
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isAdmin => widget.session?.role == AuthRole.admin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final service = await widget.repository.getServiceById(widget.serviceId);
      if (service == null) {
        throw const RepositoryException('Service was not found.');
      }
      var employees = <Employee>[];
      if (widget.repository is DemoRepository) {
        employees = await (widget.repository as DemoRepository).getEmployees();
      }
      if (!mounted) return;
      setState(() {
        _service = service;
        _employees = employees;
        _isLoading = false;
      });
    } on RepositoryException catch (exception) {
      if (!mounted) return;
      setState(() {
        _errorMessage = exception.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _edit() async {
    if (!_isAdmin || _service == null || !_service!.isActive) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ServiceFormScreen(repository: widget.repository, service: _service),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _toggleArchive() async {
    final service = _service!;
    final isRestoring = !service.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isRestoring ? 'Restore service?' : 'Archive service?'),
        content: Text(
          isRestoring
              ? 'This service will return to the active catalogue.'
              : 'Historical appointment records will remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isRestoring ? 'Restore' : 'Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (isRestoring) {
      await widget.repository.restoreService(service.id);
    } else {
      await widget.repository.archiveService(service.id);
    }
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isRestoring
                ? 'Service restored successfully.'
                : 'Service archived successfully.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_service == null) {
      return Scaffold(
        body: EmptyState(
          title: 'Unable to load service',
          subtitle: _errorMessage,
        ),
      );
    }
    final service = _service!;
    final employeeNames = service.assignedEmployeeIds
        .map(
          (id) =>
              _employees
                  .where((employee) => employee.id == id)
                  .map((employee) => employee.fullName)
                  .firstOrNull ??
              id,
        )
        .toList();
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: const Text('Service details'),
        actions: [
          if (_isAdmin && service.isActive)
            IconButton(
              tooltip: 'Edit service',
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (_isAdmin)
            IconButton(
              tooltip: service.isActive ? 'Archive service' : 'Restore service',
              onPressed: _toggleArchive,
              icon: Icon(
                service.isActive
                    ? Icons.archive_outlined
                    : Icons.unarchive_outlined,
              ),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CategoryVideoBackground(category: service.category),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.name,
                            style: AppTextStyles.headlineMedium,
                          ),
                        ),
                        StatusPill(
                          label: service.isActive ? 'Active' : 'Archived',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      service.category.label,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${service.durationLabel ?? _formatDuration(service.durationMinutes)}  |  ${service.priceLabel ?? 'Rs ${service.price.toStringAsFixed(0)}'}',
                      style: AppTextStyles.titleLarge,
                    ),
                    if (service.description.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        service.description,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text('Capable employees', style: AppTextStyles.titleLarge),
              const SizedBox(height: 8),
              AppCard(
                child: employeeNames.isEmpty
                    ? const Text('No employees assigned yet.')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: employeeNames
                            .map(
                              (name) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      color: AppColors.champagneGold,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(name),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: AppColors.champagneGold,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Completed appointments retain their original service name, category, duration, and price snapshot.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isAdmin && !service.isActive) ...[
                const SizedBox(height: 18),
                PrimaryButton(
                  label: 'Restore service',
                  onPressed: _toggleArchive,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '$hours hr' : '$hours hr $remainder min';
}
