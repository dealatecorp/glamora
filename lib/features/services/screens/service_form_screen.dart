import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/repositories.dart';
import '../../../models/salon_models.dart';

class ServiceFormScreen extends StatefulWidget {
  const ServiceFormScreen({super.key, required this.repository, this.service});

  final ServiceRepository repository;
  final Service? service;

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _durationController;
  late final TextEditingController _priceController;
  late final TextEditingController _descriptionController;
  List<Employee> _employees = [];
  Set<String> _selectedEmployeeIds = {};
  ServiceCategory? _category;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _nameController = TextEditingController(text: service?.name);
    _durationController = TextEditingController(
      text: service?.durationMinutes.toString(),
    );
    _priceController = TextEditingController(
      text: service?.price.toStringAsFixed(0),
    );
    _descriptionController = TextEditingController(text: service?.description);
    _category = service?.category;
    _selectedEmployeeIds = {...?service?.assignedEmployeeIds};
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = widget.repository is DemoRepository
        ? await (widget.repository as DemoRepository).getEmployees()
        : <Employee>[];
    if (mounted) setState(() => _employees = employees);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final duration = int.tryParse(_durationController.text.trim());
    final price = double.tryParse(_priceController.text.trim());
    if (duration == null || price == null || _category == null) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      if (_isEditing) {
        await widget.repository.updateService(
          id: widget.service!.id,
          name: _nameController.text,
          category: _category!,
          durationMinutes: duration,
          price: price,
          description: _descriptionController.text,
          assignedEmployeeIds: _selectedEmployeeIds.toList(),
        );
      } else {
        await widget.repository.createService(
          name: _nameController.text,
          category: _category!,
          durationMinutes: duration,
          price: price,
          description: _descriptionController.text,
          assignedEmployeeIds: _selectedEmployeeIds.toList(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Service updated.' : 'Service created.'),
        ),
      );
      Navigator.of(context).pop(true);
    } on RepositoryException catch (exception) {
      if (!mounted) return;
      setState(() {
        _errorMessage = exception.message;
        _isSaving = false;
      });
    }
  }

  String? _required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: Text(_isEditing ? 'Edit service' : 'Add service')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Text(
                _isEditing
                    ? 'Refine the catalogue entry'
                    : 'Create a catalogue entry',
                style: AppTextStyles.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Historical appointment snapshots remain unchanged when this service evolves.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                validator: (value) => _required(value, 'Enter a service name.'),
                decoration: const InputDecoration(labelText: 'Service name'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ServiceCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ServiceCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _category = value),
                validator: (value) =>
                    value == null ? 'Choose a category.' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final number = int.tryParse(value?.trim() ?? '');
                        return number == null || number <= 0
                            ? 'Use minutes greater than zero.'
                            : null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Duration (minutes)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final number = double.tryParse(value?.trim() ?? '');
                        return number == null || number < 0
                            ? 'Enter a valid price.'
                            : null;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Price (Rs)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 22),
              Text('Capable employees', style: AppTextStyles.titleLarge),
              const SizedBox(height: 6),
              if (_employees.isEmpty)
                Text(
                  'No employee capability data available.',
                  style: AppTextStyles.bodySmall,
                )
              else
                ..._employees.map(
                  (employee) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _selectedEmployeeIds.contains(employee.id),
                    onChanged: (selected) => setState(() {
                      if (selected == true) {
                        _selectedEmployeeIds.add(employee.id);
                      } else {
                        _selectedEmployeeIds.remove(employee.id);
                      }
                    }),
                    title: Text(employee.fullName),
                    subtitle: Text(employee.role),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isEditing ? 'Save changes' : 'Create service',
                isLoading: _isSaving,
                disabled: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
