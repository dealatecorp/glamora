import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/repositories.dart';
import '../../../models/salon_models.dart';

class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({
    super.key,
    required this.repository,
    this.employee,
  });

  final DemoRepository repository;
  final Employee? employee;

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _experienceController;
  late final TextEditingController _pinController;
  List<Service> _services = [];
  Set<String> _selectedServiceIds = {};
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final employee = widget.employee;
    _idController = TextEditingController(text: employee?.id);
    _nameController = TextEditingController(text: employee?.fullName);
    _phoneController = TextEditingController(text: employee?.phone);
    _emailController = TextEditingController(text: employee?.email);
    _experienceController = TextEditingController(
      text: employee?.experienceYears.toString(),
    );
    _pinController = TextEditingController();
    _selectedServiceIds = {...?employee?.serviceIds};
    _loadServices();
  }

  Future<void> _loadServices() async {
    final services = await widget.repository.getServices(includeArchived: true);
    if (mounted) setState(() => _services = services);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _experienceController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedServiceIds.isEmpty) {
      setState(() => _errorMessage = 'Select at least one service capability.');
      return;
    }
    final experience = int.tryParse(_experienceController.text.trim()) ?? 0;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      if (_isEditing) {
        await widget.repository.updateEmployee(
          id: widget.employee!.id,
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
          experienceYears: experience,
          serviceIds: _selectedServiceIds.toList(),
        );
        if (_pinController.text.trim().isNotEmpty) {
          await widget.repository.resetEmployeePin(
            widget.employee!.id,
            _pinController.text.trim(),
          );
        }
      } else {
        await widget.repository.createEmployee(
          id: _idController.text,
          name: _nameController.text,
          phone: _phoneController.text,
          pin: _pinController.text,
          email: _emailController.text,
          experienceYears: experience,
          serviceIds: _selectedServiceIds.toList(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Employee updated.' : 'Employee added.'),
        ),
      );
      Navigator.of(context).pop(true);
    } on RepositoryException catch (exception) {
      if (mounted) {
        setState(() {
          _errorMessage = exception.message;
          _isSaving = false;
        });
      }
    }
  }

  String? _required(String? value, String message) =>
      value == null || value.trim().isEmpty ? message : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit employee' : 'Add employee'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Text(
                _isEditing ? 'Update team profile' : 'Create team profile',
                style: AppTextStyles.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Capabilities control which services appear during appointment booking.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (!_isEditing) ...[
                TextFormField(
                  controller: _idController,
                  validator: (value) =>
                      _required(value, 'Employee ID is required.'),
                  decoration: const InputDecoration(labelText: 'Employee ID'),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _nameController,
                validator: (value) => _required(value, 'Name is required.'),
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) =>
                    value == null || !RegExp(r'^\d{10}$').hasMatch(value.trim())
                    ? 'Mobile number must be exactly 10 digits.'
                    : null,
                decoration: const InputDecoration(labelText: 'Mobile'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value != null &&
                        value.trim().isNotEmpty &&
                        !value.contains('@')
                    ? 'Enter a valid email.'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Experience (years)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pinController,
                      obscureText: true,
                      validator: (value) =>
                          !_isEditing &&
                              (value == null || value.trim().length < 4)
                          ? 'Use at least 4 characters.'
                          : null,
                      decoration: InputDecoration(
                        labelText: _isEditing
                            ? 'Reset PIN (optional)'
                            : 'PIN/password',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text('Service capabilities', style: AppTextStyles.titleLarge),
              const SizedBox(height: 6),
              ..._services.map(
                (service) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selectedServiceIds.contains(service.id),
                  onChanged: (selected) => setState(() {
                    if (selected == true) {
                      _selectedServiceIds.add(service.id);
                    } else {
                      _selectedServiceIds.remove(service.id);
                    }
                  }),
                  title: Text(service.name),
                  subtitle: Text(service.category.label),
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
                label: _isEditing ? 'Save changes' : 'Create employee',
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
