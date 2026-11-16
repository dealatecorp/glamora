import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/search_field.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../models/salon_models.dart';
import '../../payments/screens/payment_screen.dart';
import '../domain/revenue_service.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key, required this.repository});
  final DemoRepository repository;
  @override State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  late final RevenueService _service;
  RevenueSummary? _summary;
  String _query = '';
  DateTimeRange? _range;
  PaymentStatus? _status;
  PaymentMethod? _method;
  bool _loading = true;

  @override void initState() { super.initState(); _service = RevenueService(widget.repository); _load(); }
  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.summary(RevenueFilter(start: _range?.start, end: _range?.end, status: _status, method: _method));
    if (mounted) setState(() { _summary = data; _loading = false; });
  }
  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 1)), initialDateRange: _range);
    if (picked != null) { _range = picked; _load(); }
  }
  void _preset(int days) {
    final now = DateTime.now();
    _range = DateTimeRange(start: DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1)), end: now);
    _load();
  }

  @override Widget build(BuildContext context) {
    final summary = _summary;
    final records = summary?.records.where((r) => _query.isEmpty || '${r.invoice.invoiceNumber} ${r.invoice.clientName} ${r.payment?.transactionId ?? ''}'.toLowerCase().contains(_query)).toList() ?? [];
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: const Text('Revenue & Earnings')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
          Text('Revenue overview', style: AppTextStyles.displaySmall), const SizedBox(height: 6),
          Text('Billed amounts and verified receipts are shown separately.', style: AppTextStyles.bodyMedium), const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final item in [('Today', () => _preset(1)), ('This week', () => _preset(7)), ('This month', () => _preset(30)), ('Custom range', _pickRange)]) ActionChip(label: Text(item.$1), onPressed: item.$2)]),
          if (_range != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('${_range!.start.day}/${_range!.start.month}/${_range!.start.year} – ${_range!.end.day}/${_range!.end.month}/${_range!.end.year}', style: AppTextStyles.caption)), const SizedBox(height: 10),
          Wrap(spacing: 8, children: [ChoiceChip(label: const Text('All statuses'), selected: _status == null, onSelected: (_) { _status = null; _load(); }), ...PaymentStatus.values.map((status) => ChoiceChip(label: Row(mainAxisSize: MainAxisSize.min, children: [PaymentStatusDot(status: status), const SizedBox(width: 6), Text(status.name)]), selected: _status == status, onSelected: (_) { _status = _status == status ? null : status; _load(); })), ChoiceChip(label: const Text('Reset'), selected: false, onSelected: (_) { _range = null; _status = null; _method = null; _load(); })]), const SizedBox(height: 8),
          DropdownButtonFormField<PaymentMethod>(value: _method, decoration: const InputDecoration(labelText: 'Payment method'), items: [const DropdownMenuItem(value: null, child: Text('All methods')), ...PaymentMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.name)))], onChanged: (value) { _method = value; _load(); }), const SizedBox(height: 16),
          if (_loading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())) else if (summary!.records.isEmpty) const EmptyState(title: 'No revenue records found for the selected filters.') else ...[
            _Summary(summary: summary), const SizedBox(height: 16), SearchField(hintText: 'Search invoice, client, or reference', onChanged: (value) => setState(() => _query = value.trim().toLowerCase())), const SizedBox(height: 12), Text('Revenue history', style: AppTextStyles.titleLarge), const SizedBox(height: 8),
            if (records.isEmpty) const EmptyState(title: 'No matching revenue records.') else ...records.map((record) => Padding(padding: const EdgeInsets.only(bottom: 10), child: AppCard(padding: EdgeInsets.zero, child: ListTile(onTap: record.payment == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(invoiceId: record.invoice.id, repository: widget.repository))), title: Text(record.invoice.invoiceNumber), subtitle: Text('${record.invoice.clientName} · ${record.invoice.issuedAt.day}/${record.invoice.issuedAt.month}/${record.invoice.issuedAt.year}'), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('Rs ${record.received.toStringAsFixed(0)}', style: AppTextStyles.titleMedium), StatusPill(label: record.payment?.status.name ?? 'pending', paymentStatus: record.payment?.status ?? PaymentStatus.pending)]))))),
          ],
        ]),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});
  final RevenueSummary summary;
  @override Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [('Billed', summary.billed), ('Received', summary.received), ('Pending', summary.pending), ('Refunded', summary.refunded)].map((item) => SizedBox(width: 150, child: AppCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.$1, style: AppTextStyles.caption), const SizedBox(height: 4), Text('Rs ${item.$2.toStringAsFixed(0)}', style: AppTextStyles.titleLarge)])))).toList());
}
