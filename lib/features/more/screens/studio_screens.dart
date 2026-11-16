import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/repositories/repositories.dart';
import '../../../models/salon_models.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key, required this.repository});

  final SettingsRepository repository;

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  late Future<BusinessProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.repository.getBusinessProfile();
  }

  Future<void> _edit(BusinessProfile profile) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BusinessProfileEditScreen(
          repository: widget.repository,
          profile: profile,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() => _profileFuture = widget.repository.getBusinessProfile());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => _StudioDataFuture<BusinessProfile>(
    title: 'Business Profile',
    future: _profileFuture,
    builder: (profile) => ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text(profile.salonName, style: AppTextStyles.displaySmall),
        const SizedBox(height: 6),
        Text(profile.tagline, style: AppTextStyles.bodyMedium),
        const SizedBox(height: 18),
        _EditButton(onPressed: () => _edit(profile)),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(label: 'Address', value: profile.address),
              _InfoRow(label: 'Phone', value: profile.phone),
              _InfoRow(label: 'Email', value: profile.email),
              _InfoRow(label: 'Currency', value: profile.currency),
            ],
          ),
        ),
      ],
    ),
  );
}

class BusinessHoursScreen extends StatefulWidget {
  const BusinessHoursScreen({super.key, required this.repository});

  final SettingsRepository repository;

  @override
  State<BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends State<BusinessHoursScreen> {
  late Future<List<BusinessHours>> _hoursFuture;

  @override
  void initState() {
    super.initState();
    _hoursFuture = widget.repository.getBusinessHours();
  }

  Future<void> _edit(List<BusinessHours> hours) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BusinessHoursEditScreen(
          repository: widget.repository,
          hours: hours,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() => _hoursFuture = widget.repository.getBusinessHours());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business hours saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => _StudioDataFuture<List<BusinessHours>>(
    title: 'Business Hours',
    future: _hoursFuture,
    builder: (hours) => ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Salon schedule', style: AppTextStyles.displaySmall),
        const SizedBox(height: 6),
        Text(
          'Appointments follow these operating hours.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 18),
        _EditButton(onPressed: () => _edit(hours)),
        const SizedBox(height: 8),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: hours
                .map(
                  (item) => ListTile(
                    title: Text(item.dayName, style: AppTextStyles.titleMedium),
                    trailing: Text(
                      item.isClosed
                          ? 'Closed'
                          : '${item.openTime} – ${item.closeTime}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    ),
  );
}

class SalonBreaksScreen extends StatefulWidget {
  const SalonBreaksScreen({super.key, required this.repository});

  final SettingsRepository repository;

  @override
  State<SalonBreaksScreen> createState() => _SalonBreaksScreenState();
}

class _SalonBreaksScreenState extends State<SalonBreaksScreen> {
  late Future<List<SalonBreak>> _breaksFuture;

  @override
  void initState() {
    super.initState();
    _breaksFuture = widget.repository.getSalonBreaks();
  }

  Future<void> _edit(List<SalonBreak> breaks) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => SalonBreaksEditScreen(
          repository: widget.repository,
          breaks: breaks,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() => _breaksFuture = widget.repository.getSalonBreaks());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Breaks saved.')));
    }
  }

  @override
  Widget build(BuildContext context) => _StudioDataFuture<List<SalonBreak>>(
    title: 'Breaks',
    future: _breaksFuture,
    builder: (breaks) => ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Salon breaks', style: AppTextStyles.displaySmall),
        const SizedBox(height: 6),
        Text(
          'These times are blocked from appointment availability.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 18),
        _EditButton(onPressed: () => _edit(breaks)),
        const SizedBox(height: 8),
        if (breaks.isEmpty)
          const EmptyState(title: 'No breaks configured.')
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: breaks
                  .map(
                    (item) => ListTile(
                      leading: const Icon(
                        Icons.free_breakfast_outlined,
                        color: AppColors.champagneGold,
                      ),
                      title: Text(item.title, style: AppTextStyles.titleMedium),
                      subtitle: Text(
                        '${item.date.day}/${item.date.month}/${item.date.year}',
                      ),
                      trailing: Text(
                        '${item.startTime} – ${item.endTime}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    ),
  );
}

class ApplicationSettingsScreen extends StatefulWidget {
  const ApplicationSettingsScreen({super.key, required this.repository});

  final SettingsRepository repository;

  @override
  State<ApplicationSettingsScreen> createState() =>
      _ApplicationSettingsScreenState();
}

class _ApplicationSettingsScreenState extends State<ApplicationSettingsScreen> {
  late Future<ApplicationSettings> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = widget.repository.getApplicationSettings();
  }

  Future<void> _edit(ApplicationSettings settings) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ApplicationSettingsEditScreen(
          repository: widget.repository,
          settings: settings,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(
        () => _settingsFuture = widget.repository.getApplicationSettings(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application settings saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => _StudioDataFuture<ApplicationSettings>(
    title: 'Application Settings',
    future: _settingsFuture,
    builder: (settings) => ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('App preferences', style: AppTextStyles.displaySmall),
        const SizedBox(height: 6),
        Text(
          'Defaults used by the local Glamora demo.',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 18),
        _EditButton(onPressed: () => _edit(settings)),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            children: [
              _InfoRow(
                label: 'Default appointment duration',
                value: '${settings.defaultAppointmentDuration} minutes',
              ),
              _InfoRow(
                label: 'Reminder default',
                value: '${settings.reminderHours} hours before',
              ),
              _InfoRow(
                label: 'Notifications',
                value: settings.notificationsEnabled ? 'Enabled' : 'Disabled',
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Edit'),
    ),
  );
}

class BusinessProfileEditScreen extends StatefulWidget {
  const BusinessProfileEditScreen({
    super.key,
    required this.repository,
    required this.profile,
  });

  final SettingsRepository repository;
  final BusinessProfile profile;

  @override
  State<BusinessProfileEditScreen> createState() =>
      _BusinessProfileEditScreenState();
}

class _BusinessProfileEditScreenState extends State<BusinessProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _tagline;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _currency;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.salonName);
    _tagline = TextEditingController(text: widget.profile.tagline);
    _address = TextEditingController(text: widget.profile.address);
    _phone = TextEditingController(text: widget.profile.phone);
    _email = TextEditingController(text: widget.profile.email);
    _currency = TextEditingController(text: widget.profile.currency);
  }

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _currency.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.repository.updateBusinessProfile(
        BusinessProfile(
          id: widget.profile.id,
          salonName: _name.text.trim(),
          tagline: _tagline.text.trim(),
          address: _address.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          logoUrl: widget.profile.logoUrl,
          createdAt: widget.profile.createdAt,
          currency: _currency.text.trim().toUpperCase(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on RepositoryException catch (exception) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  @override
  Widget build(BuildContext context) => _EditScaffold(
    title: 'Edit Business Profile',
    saving: _saving,
    onSave: _save,
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          _EditField(controller: _name, label: 'Salon name'),
          _EditField(controller: _tagline, label: 'Tagline'),
          _EditField(controller: _address, label: 'Address'),
          _EditField(controller: _phone, label: 'Phone'),
          _EditField(
            controller: _email,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          _EditField(controller: _currency, label: 'Currency'),
        ],
      ),
    ),
  );
}

class BusinessHoursEditScreen extends StatefulWidget {
  const BusinessHoursEditScreen({
    super.key,
    required this.repository,
    required this.hours,
  });

  final SettingsRepository repository;
  final List<BusinessHours> hours;

  @override
  State<BusinessHoursEditScreen> createState() =>
      _BusinessHoursEditScreenState();
}

class _BusinessHoursEditScreenState extends State<BusinessHoursEditScreen> {
  late final List<_HoursDraft> _drafts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _drafts = widget.hours.map(_HoursDraft.fromModel).toList();
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    for (final draft in _drafts) {
      if (draft.open.text.trim().isEmpty || draft.close.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening and closing times are required.'),
          ),
        );
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await widget.repository.updateBusinessHours(
        _drafts
            .map(
              (draft) => BusinessHours(
                id: draft.id,
                dayName: draft.dayName,
                openTime: draft.open.text.trim(),
                closeTime: draft.close.text.trim(),
                isClosed: draft.isClosed,
              ),
            )
            .toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on RepositoryException catch (exception) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  @override
  Widget build(BuildContext context) => _EditScaffold(
    title: 'Edit Business Hours',
    saving: _saving,
    onSave: _save,
    child: Column(
      children: _drafts
          .map(
            (draft) => AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          draft.dayName,
                          style: AppTextStyles.titleMedium,
                        ),
                      ),
                      Switch(
                        value: draft.isClosed,
                        onChanged: (value) =>
                            setState(() => draft.isClosed = value),
                      ),
                      Text(draft.isClosed ? 'Closed' : 'Open'),
                    ],
                  ),
                  if (!draft.isClosed) ...[
                    _EditField(controller: draft.open, label: 'Opens (HH:MM)'),
                    _EditField(
                      controller: draft.close,
                      label: 'Closes (HH:MM)',
                    ),
                  ],
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

class _HoursDraft {
  _HoursDraft.fromModel(BusinessHours value)
    : id = value.id,
      dayName = value.dayName,
      open = TextEditingController(text: value.openTime),
      close = TextEditingController(text: value.closeTime),
      isClosed = value.isClosed;

  final String id;
  final String dayName;
  final TextEditingController open;
  final TextEditingController close;
  bool isClosed;

  void dispose() {
    open.dispose();
    close.dispose();
  }
}

class SalonBreaksEditScreen extends StatefulWidget {
  const SalonBreaksEditScreen({
    super.key,
    required this.repository,
    required this.breaks,
  });

  final SettingsRepository repository;
  final List<SalonBreak> breaks;

  @override
  State<SalonBreaksEditScreen> createState() => _SalonBreaksEditScreenState();
}

class _SalonBreaksEditScreenState extends State<SalonBreaksEditScreen> {
  late final List<_BreakDraft> _drafts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _drafts = widget.breaks.map(_BreakDraft.fromModel).toList();
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_drafts.any((draft) => draft.title.text.trim().isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Break title is required.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.updateSalonBreaks(
        _drafts
            .map(
              (draft) => SalonBreak(
                id: draft.id,
                title: draft.title.text.trim(),
                startTime: draft.start.text.trim(),
                endTime: draft.end.text.trim(),
                date: draft.date,
              ),
            )
            .toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on RepositoryException catch (exception) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  Future<void> _pickDate(_BreakDraft draft) async {
    final date = await showDatePicker(
      context: context,
      initialDate: draft.date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (date != null && mounted) setState(() => draft.date = date);
  }

  @override
  Widget build(BuildContext context) => _EditScaffold(
    title: 'Edit Breaks',
    saving: _saving,
    onSave: _save,
    child: _drafts.isEmpty
        ? const EmptyState(title: 'No breaks configured.')
        : Column(
            children: _drafts
                .map(
                  (draft) => AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        _EditField(controller: draft.title, label: 'Title'),
                        _EditField(
                          controller: draft.start,
                          label: 'Starts (HH:MM)',
                        ),
                        _EditField(
                          controller: draft.end,
                          label: 'Ends (HH:MM)',
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _pickDate(draft),
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              'Date: ${draft.date.day}/${draft.date.month}/${draft.date.year}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
  );
}

class _BreakDraft {
  _BreakDraft.fromModel(SalonBreak value)
    : id = value.id,
      title = TextEditingController(text: value.title),
      start = TextEditingController(text: value.startTime),
      end = TextEditingController(text: value.endTime),
      date = value.date;

  final String id;
  final TextEditingController title;
  final TextEditingController start;
  final TextEditingController end;
  DateTime date;

  void dispose() {
    title.dispose();
    start.dispose();
    end.dispose();
  }
}

class ApplicationSettingsEditScreen extends StatefulWidget {
  const ApplicationSettingsEditScreen({
    super.key,
    required this.repository,
    required this.settings,
  });

  final SettingsRepository repository;
  final ApplicationSettings settings;

  @override
  State<ApplicationSettingsEditScreen> createState() =>
      _ApplicationSettingsEditScreenState();
}

class _ApplicationSettingsEditScreenState
    extends State<ApplicationSettingsEditScreen> {
  late final TextEditingController _duration;
  late final TextEditingController _reminder;
  late bool _notificationsEnabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _duration = TextEditingController(
      text: widget.settings.defaultAppointmentDuration.toString(),
    );
    _reminder = TextEditingController(
      text: widget.settings.reminderHours.toString(),
    );
    _notificationsEnabled = widget.settings.notificationsEnabled;
  }

  @override
  void dispose() {
    _duration.dispose();
    _reminder.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final duration = int.tryParse(_duration.text.trim());
    final reminder = int.tryParse(_reminder.text.trim());
    if (duration == null || duration <= 0 || reminder == null || reminder < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid duration and reminder values.'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.updateApplicationSettings(
        ApplicationSettings(
          defaultAppointmentDuration: duration,
          reminderHours: reminder,
          notificationsEnabled: _notificationsEnabled,
          customerBookingUrl: widget.settings.customerBookingUrl,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on RepositoryException catch (exception) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    }
  }

  @override
  Widget build(BuildContext context) => _EditScaffold(
    title: 'Edit Application Settings',
    saving: _saving,
    onSave: _save,
    child: Column(
      children: [
        _EditField(
          controller: _duration,
          label: 'Default appointment duration (minutes)',
          keyboardType: TextInputType.number,
        ),
        _EditField(
          controller: _reminder,
          label: 'Reminder default (hours)',
          keyboardType: TextInputType.number,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Notifications enabled'),
          value: _notificationsEnabled,
          onChanged: (value) => setState(() => _notificationsEnabled = value),
        ),
      ],
    ),
  );
}

class _EditScaffold extends StatelessWidget {
  const _EditScaffold({
    required this.title,
    required this.child,
    required this.saving,
    required this.onSave,
  });

  final String title;
  final Widget child;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.warmIvory,
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          AppCard(child: child),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(saving ? 'Saving...' : 'Save changes'),
          ),
        ],
      ),
    ),
  );
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.controller,
    required this.label,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required.' : null,
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: AppTextStyles.bodySmall)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    ),
  );
}

class _StudioDataFuture<T> extends StatelessWidget {
  const _StudioDataFuture({
    required this.title,
    required this.future,
    required this.builder,
  });

  final String title;
  final Future<T> future;
  final Widget Function(T value) builder;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.warmIvory,
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: FutureBuilder<T>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const EmptyState(title: 'Unable to load studio settings.');
          }
          return builder(snapshot.data as T);
        },
      ),
    ),
  );
}
