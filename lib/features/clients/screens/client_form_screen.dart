import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/repositories.dart';
import '../../../models/salon_models.dart';

class ClientFormScreen extends StatefulWidget {
  const ClientFormScreen({super.key, required this.repository, this.client});

  final ClientRepository repository;
  final Client? client;

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.client != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.client?.fullName);
    _phoneController = TextEditingController(text: widget.client?.phone);
    _emailController = TextEditingController(text: widget.client?.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      if (_isEditing) {
        await widget.repository.updateClient(
          id: widget.client!.id,
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
        );
      } else {
        await widget.repository.createClient(
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Client updated.' : 'Client added.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: Text(_isEditing ? 'Edit client' : 'Add client')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Text(
                _isEditing ? 'Update client profile' : 'New client profile',
                style: AppTextStyles.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Required fields are marked for a smooth front-desk handoff.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 24),
              _Field(
                label: 'Name',
                controller: _nameController,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the client name.'
                    : null,
              ),
              const SizedBox(height: 16),
              _Field(
                label: 'Mobile number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) =>
                    value == null || !RegExp(r'^\d{10}$').hasMatch(value.trim())
                    ? 'Mobile number must be exactly 10 digits.'
                    : null,
              ),
              const SizedBox(height: 16),
              _Field(
                label: 'Email (optional)',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null &&
                      value.trim().isNotEmpty &&
                      !value.contains('@')) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              PrimaryButton(
                label: _isEditing ? 'Save changes' : 'Create client',
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

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.autovalidateMode,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: autovalidateMode,
      decoration: InputDecoration(labelText: label),
    );
  }
}
