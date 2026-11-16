import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../features/auth/models/auth_session.dart';
import '../../../models/salon_models.dart';
import 'client_details_screen.dart';
import 'client_form_screen.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({
    super.key,
    required this.session,
    required this.repository,
    this.initialShowVipOnly = false,
  });

  final AuthSession? session;
  final ClientRepository repository;
  final bool initialShowVipOnly;

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final _searchController = TextEditingController();
  List<Client> _clients = [];
  bool _isLoading = true;
  late bool _showVipOnly;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _showVipOnly = widget.initialShowVipOnly;
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final clients = await widget.repository.searchClients(
        _searchController.text,
      );
      final appointments = widget.session?.isEmployee == true
          ? await (widget.repository as DemoRepository).getEmployeeAppointments(
              widget.session!.employeeId!,
            )
          : const <Appointment>[];
      final relevantClientIds = appointments
          .map((item) => item.clientId)
          .toSet();
      if (!mounted) return;
      setState(() {
        _clients = clients
            .where(
              (client) =>
                  !client.isArchived &&
                  (widget.session?.isEmployee != true ||
                      relevantClientIds.contains(client.id)),
            )
            .toList();
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

  List<Client> get _visibleClients => _showVipOnly
      ? _clients.where((client) => client.isVip).toList()
      : _clients;

  Future<void> _openForm([Client? client]) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            ClientFormScreen(repository: widget.repository, client: client),
      ),
    );
    if (changed == true) _loadClients();
  }

  Future<void> _openDetails(Client client) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClientDetailsScreen(
          clientId: client.id,
          repository: widget.repository,
          session: widget.session,
        ),
      ),
    );
    if (changed == true) _loadClients();
  }

  @override
  Widget build(BuildContext context) {
    final visibleClients = _visibleClients;
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          IconButton(
            tooltip: 'Add client',
            onPressed: () => _openForm(),
            icon: const Icon(Icons.person_add_alt_1_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadClients,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text('Client relationships', style: AppTextStyles.displaySmall),
              const SizedBox(height: 6),
              Text(
                'Keep every visit and preference close at hand.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 18),
              SearchField(
                hintText: 'Search name, mobile, service, amount...',
                controller: _searchController,
                onChanged: (_) => _loadClients(),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _FilterButton(
                      label: 'All Clients',
                      selected: !_showVipOnly,
                      onTap: () => setState(() => _showVipOnly = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FilterButton(
                      label: 'VIP Clients',
                      selected: _showVipOnly,
                      onTap: () => setState(() => _showVipOnly = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                EmptyState(
                  title: 'Unable to load clients',
                  subtitle: _errorMessage,
                )
              else if (visibleClients.isEmpty)
                EmptyState(
                  title: _searchController.text.isEmpty
                      ? 'No clients found.'
                      : 'No clients match your search.',
                  subtitle: _showVipOnly
                      ? 'VIP clients will appear here after qualifying visits.'
                      : null,
                  actionLabel: 'Add client',
                  onAction: () => _openForm(),
                )
              else
                ...visibleClients.map(
                  (client) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ClientCard(
                      client: client,
                      onTap: () => _openDetails(client),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Add client', onPressed: () => _openForm()),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        backgroundColor: selected ? AppColors.cream : AppColors.white,
        side: BorderSide(
          color: selected ? AppColors.champagneGold : AppColors.border,
        ),
      ),
      child: Text(label),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client, required this.onTap});

  final Client client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.cream,
              foregroundColor: AppColors.espresso,
              child: Text(client.fullName.substring(0, 1).toUpperCase()),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(client.fullName, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    client.phone ?? 'No mobile number',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${client.visitCount} visits  |  ${client.loyaltyPoints} XP',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            if (client.isVip) const StatusPill(label: 'VIP'),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedTaupe,
            ),
          ],
        ),
      ),
    );
  }
}
