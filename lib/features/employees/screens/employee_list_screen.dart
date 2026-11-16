import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../models/salon_models.dart';
import 'employee_details_screen.dart';
import 'employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key, required this.repository});

  final DemoRepository repository;

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  List<Employee> _employees = [];
  Map<String, int> _clientsServed = {};
  String _query = '';
  bool _showArchived = false;
  bool _isLoading = true;
  String? _errorMessage;

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
      final employees = await widget.repository.searchEmployees(
        _query,
        includeArchived: _showArchived,
      );
      final appointments = await widget.repository.getAppointments();
      final clientsServed = <String, Set<String>>{};
      for (final appointment in appointments.where(
        (item) => item.status == AppointmentStatus.completed,
      )) {
        for (final service in appointment.services) {
          if (service.employeeId != null) {
            (clientsServed[service.employeeId!] ??= <String>{})
                .add(appointment.clientId);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _employees = employees;
        _clientsServed = clientsServed.map((id, clients) => MapEntry(id, clients.length));
        _isLoading = false;
      });
    } on RepositoryException catch (exception) {
      if (mounted)
        setState(() {
          _errorMessage = exception.message;
          _isLoading = false;
        });
    }
  }

  Future<void> _openForm([Employee? employee]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EmployeeFormScreen(
          repository: widget.repository,
          employee: employee,
        ),
      ),
    );
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            tooltip: _showArchived
                ? 'Show active employees'
                : 'Show archived employees',
            onPressed: () {
              setState(() => _showArchived = !_showArchived);
              _load();
            },
            icon: Icon(
              _showArchived ? Icons.visibility_rounded : Icons.archive_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Add employee',
            onPressed: () => _openForm(),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text('Team directory', style: AppTextStyles.displaySmall),
              const SizedBox(height: 6),
              Text(
                'Keep capabilities, histories, and recognition in one place.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 18),
              SearchField(
                hintText: 'Search name, ID, or email',
                onChanged: (value) {
                  _query = value;
                  _load();
                },
              ),
              const SizedBox(height: 14),
              StatusPill(
                label: _showArchived
                    ? 'Showing archived employees'
                    : 'Active employees',
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                EmptyState(
                  title: 'Unable to load employees',
                  subtitle: _errorMessage,
                )
              else if (_employees.isEmpty)
                const EmptyState(title: 'No employees found.')
              else
                ..._employees.map(
                  (employee) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _EmployeeCard(
                      employee: employee,
                      clientsServed: _clientsServed[employee.id] ?? 0,
                      onTap: () async {
                        final changed = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => EmployeeDetailsScreen(
                              employeeId: employee.id,
                              repository: widget.repository,
                            ),
                          ),
                        );
                        if (changed == true) _load();
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: 'Add employee',
                onPressed: () => _openForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard({required this.employee, required this.clientsServed, required this.onTap});

  final Employee employee;
  final int clientsServed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(16),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.cream,
            foregroundColor: AppColors.espresso,
            child: Text(employee.fullName.substring(0, 1)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.fullName, style: AppTextStyles.titleLarge),
                Text(employee.id, style: AppTextStyles.bodySmall),
                Text(
                  '${employee.experienceYears} years  |  ${employee.serviceIds.length} capabilities  |  $clientsServed clients  |  ${employee.rewardXp} XP',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          StatusPill(
            label: employee.isActive ? 'Active' : 'Archived',
            showSuccessDot: employee.isActive,
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.mutedTaupe),
        ],
      ),
    ),
  );
}
