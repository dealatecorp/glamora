import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../features/auth/models/auth_role.dart';
import '../../../features/auth/models/auth_session.dart';
import '../../../models/salon_models.dart';
import 'service_details_screen.dart';
import 'service_form_screen.dart';
import '../widgets/category_video_background.dart';

class ServiceListScreen extends StatefulWidget {
  const ServiceListScreen({
    super.key,
    required this.session,
    required this.repository,
    this.employeeId,
  });

  final AuthSession? session;
  final ServiceRepository repository;
  final String? employeeId;

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _searchController = TextEditingController();
  List<Service> _services = [];
  ServiceCategory? _category;
  bool _showArchived = false;
  bool _isLoading = true;
  String? _errorMessage;

  bool get _isAdmin => widget.session?.role == AuthRole.admin;
  bool get _isAssignedServicesView => widget.employeeId != null;
  bool get _canAddService => _isAdmin || widget.session?.isEmployee == true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final services = await widget.repository.getServices(
        includeArchived: _isAdmin && _showArchived,
      );
      final query = _searchController.text.trim().toLowerCase();
      final serviceOrder = {
        for (final entry in services.indexed) entry.$2.id: entry.$1,
      };
      if (!mounted) return;
      setState(() {
        _services = services.where((service) {
          final matchesEmployee =
              widget.employeeId == null ||
              service.assignedEmployeeIds.contains(widget.employeeId);
          final matchesCategory =
              _category == null || service.category == _category;
          final matchesSearch =
              query.isEmpty ||
              service.name.toLowerCase().contains(query) ||
              service.category.label.toLowerCase().contains(query);
          return matchesEmployee && matchesCategory && matchesSearch;
        }).toList()
          ..sort(
            (first, second) => _compareServicesForDisplay(
              first,
              second,
              serviceOrder,
            ),
          );
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

  int _compareServicesForDisplay(
    Service first,
    Service second,
    Map<String, int> serviceOrder,
  ) {
    final categoryOrder = first.category.index.compareTo(second.category.index);
    if (categoryOrder != 0) return categoryOrder;

    final durationOrder = first.durationMinutes.compareTo(
      second.durationMinutes,
    );
    if (durationOrder != 0) return durationOrder;

    return (serviceOrder[first.id] ?? 0).compareTo(serviceOrder[second.id] ?? 0);
  }

  Future<void> _openForm([Service? service]) async {
    if (!_canAddService) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ServiceFormScreen(repository: widget.repository, service: service),
      ),
    );
    if (changed == true) _loadServices();
  }

  Future<void> _openDetails(Service service) async {
    final changed = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        transitionDuration: const Duration(milliseconds: 550),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, _, _) => ServiceDetailsScreen(
          serviceId: service.id,
          repository: widget.repository,
          session: widget.session,
        ),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    if (changed == true) _loadServices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(_isAssignedServicesView ? 'Assigned services' : 'Services'),
        actions: [
          if (_isAdmin)
            IconButton(
              tooltip: _showArchived
                  ? 'Show active services'
                  : 'Show archived services',
              onPressed: () {
                setState(() => _showArchived = !_showArchived);
                _loadServices();
              },
              icon: Icon(
                _showArchived
                    ? Icons.visibility_rounded
                    : Icons.archive_outlined,
              ),
            ),
          if (_canAddService)
            IconButton(
              tooltip: 'Add service',
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_business_rounded),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CategoryVideoBackground(category: _category),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadServices,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Text(
                    _isAssignedServicesView
                        ? 'Assigned services'
                        : 'Service catalogue',
                    style: AppTextStyles.displaySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isAssignedServicesView
                        ? 'Services assigned to your employee profile.'
                        : 'A considered menu of care for every kind of visit.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  SearchField(
                    hintText: 'Search service or category',
                    controller: _searchController,
                    onChanged: (_) => _loadServices(),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryChip(
                          label: 'All',
                          selected: _category == null,
                          onTap: () {
                            setState(() => _category = null);
                            _loadServices();
                          },
                        ),
                        ...ServiceCategory.values.map(
                          (category) => _CategoryChip(
                            label: category.label,
                            selected: _category == category,
                            onTap: () {
                              setState(() => _category = category);
                              _loadServices();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showArchived) ...[
                    const SizedBox(height: 10),
                    const StatusPill(label: 'Showing archived services'),
                  ],
                  const SizedBox(height: 18),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.all(48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                    EmptyState(
                      title: 'Unable to load services',
                      subtitle: _errorMessage,
                    )
                  else if (_services.isEmpty)
                    EmptyState(
                      title: _searchController.text.isEmpty
                          ? _isAssignedServicesView
                                ? 'No assigned services found.'
                                : 'No services found.'
                          : 'No services match your search.',
                      actionLabel: _canAddService ? 'Add service' : null,
                      onAction: _canAddService ? () => _openForm() : null,
                    )
                  else
                    ..._services.map(
                      (service) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ServiceCard(
                          service: service,
                          onTap: () => _openDetails(service),
                        ),
                      ),
                    ),
                  if (_canAddService) ...[
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: 'Add service',
                      onPressed: () => _openForm(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.cream,
      side: BorderSide(
        color: selected ? AppColors.champagneGold : AppColors.border,
      ),
      labelStyle: AppTextStyles.caption.copyWith(color: AppColors.espresso),
    ),
  );
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.content_cut_rounded,
              color: AppColors.champagneGold,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text(service.category.label, style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text(
                  '${service.durationLabel ?? _formatDuration(service.durationMinutes)}  |  ${service.priceLabel ?? 'Rs ${service.price.toStringAsFixed(0)}'}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${service.assignedEmployeeIds.length} capable employee${service.assignedEmployeeIds.length == 1 ? '' : 's'}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          if (!service.isActive) const StatusPill(label: 'Archived'),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mutedTaupe),
        ],
      ),
    ),
  );
}

String _formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '$hours hr' : '$hours hr $remainder min';
}
