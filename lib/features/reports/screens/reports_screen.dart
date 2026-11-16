import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../data/repositories/repositories.dart';
import '../../../models/salon_models.dart';
import '../domain/revenue_service.dart';

enum ReportType {
  revenue,
  payments,
  appointments,
  clients,
  inventory,
  employees,
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.repository});

  final DemoRepository repository;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportType _type = ReportType.revenue;
  DateTimeRange? _range;
  List<String> _headers = [];
  List<List<String>> _rows = [];
  bool _loading = false;
  bool _exporting = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final report = await _buildReport();
      if (!mounted) return;
      setState(() {
        _headers = report.headers;
        _rows = report.rows;
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report generated.')));
    } on RepositoryException catch (exception) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(exception.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate the report.')),
      );
    }
  }

  Future<_ReportTable> _buildReport() async {
    final filter = RevenueFilter(start: _range?.start, end: _range?.end);
    final rows = <List<String>>[];

    switch (_type) {
      case ReportType.revenue:
      case ReportType.payments:
        final report = await RevenueService(widget.repository).summary(filter);
        final headers = _type == ReportType.revenue
            ? [
                'Invoice',
                'Date',
                'Client',
                'Billed',
                'Received',
                'Pending',
                'Refunded',
                'Method',
                'Status',
              ]
            : [
                'Payment ID',
                'Invoice',
                'Client',
                'Date',
                'Amount',
                'Method',
                'Reference',
                'Status',
              ];
        for (final item in report.records) {
          final payment = item.payment;
          rows.add(
            _type == ReportType.revenue
                ? [
                    item.invoice.invoiceNumber,
                    '${item.invoice.issuedAt}',
                    item.invoice.clientName,
                    '${item.billed}',
                    '${item.received}',
                    '${item.pending}',
                    '${item.refunded}',
                    payment?.method.name ?? '',
                    payment?.status.name ?? 'pending',
                  ]
                : [
                    payment?.id ?? '',
                    item.invoice.invoiceNumber,
                    item.invoice.clientName,
                    '${item.invoice.issuedAt}',
                    '${payment?.amount ?? 0}',
                    payment?.method.name ?? '',
                    payment?.transactionId ?? '',
                    payment?.status.name ?? 'pending',
                  ],
          );
        }
        return _ReportTable(headers: headers, rows: rows);

      case ReportType.appointments:
        final headers = [
          'Appointment',
          'Client',
          'Date/time',
          'Services',
          'Employee',
          'Status',
          'Payment status',
        ];
        for (final appointment in await widget.repository.getAppointments()) {
          if (_range == null || filter.includes(appointment.startAt)) {
            rows.add([
              appointment.id,
              appointment.clientName,
              '${appointment.startAt}',
              appointment.services
                  .map((service) => service.serviceName)
                  .join(', '),
              appointment.employeeName ?? '',
              appointment.status.name,
              appointment.paymentStatus.name,
            ]);
          }
        }
        return _ReportTable(headers: headers, rows: rows);

      case ReportType.clients:
        final headers = [
          'Client',
          'Phone',
          'Email',
          'Visits',
          'Loyalty points',
          'VIP',
        ];
        for (final client in await widget.repository.getClients()) {
          rows.add([
            client.fullName,
            client.phone ?? '',
            client.email ?? '',
            '${client.visitCount}',
            '${client.loyaltyPoints}',
            '${client.isVip}',
          ]);
        }
        return _ReportTable(headers: headers, rows: rows);

      case ReportType.inventory:
        final headers = [
          'Product',
          'Category',
          'Quantity',
          'Low-stock threshold',
          'Cost',
          'Status',
        ];
        for (final product in await widget.repository.getProducts(
          includeArchived: true,
        )) {
          rows.add([
            product.name,
            product.category,
            '${product.quantityOnHand}',
            '${product.lowStockThreshold}',
            '${product.unitPrice}',
            product.isActive ? product.stockStatus.label : 'Archived',
          ]);
        }
        return _ReportTable(headers: headers, rows: rows);

      case ReportType.employees:
        final headers = [
          'Employee',
          'Role',
          'Specialty',
          'Active',
          'Experience',
          'Reward XP',
        ];
        for (final employee in await widget.repository.getEmployees(
          includeArchived: true,
        )) {
          rows.add([
            employee.fullName,
            employee.role,
            employee.specialty ?? '',
            '${employee.isActive}',
            '${employee.experienceYears}',
            '${employee.rewardXp}',
          ]);
        }
        return _ReportTable(headers: headers, rows: rows);
    }
  }

  Future<void> _export(bool pdf) async {
    if (_headers.isEmpty || _rows.isEmpty || _exporting) return;
    setState(() => _exporting = true);
    try {
      final service = ReportExportService();
      final name = '${_type.name} report';
      final file = pdf
          ? await service.exportPdf(
              title: name,
              lines: [
                _headers.join(' | '),
                ..._rows.map((row) => row.join(' | ')),
              ],
            )
          : await service.exportCsv(
              title: name,
              headers: _headers,
              rows: _rows,
            );
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pdf ? 'PDF' : 'CSV'} prepared: ${file.path}'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _exporting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate the report file.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.warmIvory,
    appBar: AppBar(title: const Text('Reports')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Studio reports', style: AppTextStyles.displaySmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<ReportType>(
          value: _type,
          decoration: const InputDecoration(labelText: 'Report type'),
          items: ReportType.values
              .map(
                (type) => DropdownMenuItem(
                  value: type,
                  child: Text(
                    type.name[0].toUpperCase() + type.name.substring(1),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _type = value!;
            _headers = [];
            _rows = [];
          }),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            final value = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (value != null) {
              setState(() {
                _range = value;
                _headers = [];
                _rows = [];
              });
            }
          },
          child: Text(
            _range == null
                ? 'Optional date range'
                : '${_range!.start.day}/${_range!.start.month}/${_range!.start.year} - ${_range!.end.day}/${_range!.end.month}/${_range!.end.year}',
          ),
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: 'Generate report',
          isLoading: _loading,
          disabled: _loading,
          onPressed: _generate,
        ),
        const SizedBox(height: 20),
        if (_headers.isNotEmpty) ...[
          Text('Preview', style: AppTextStyles.titleLarge),
          const SizedBox(height: 8),
          if (_rows.isEmpty)
            const EmptyState(title: 'No records match this report.')
          else
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_rows.length} records prepared',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(_headers.join(' - '), style: AppTextStyles.caption),
                  const Divider(),
                  ..._rows.take(5).map(
                    (row) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: _PreviewRow(type: _type, row: row),
                    ),
                  ),
                  if (_rows.length > 5)
                    Text(
                      '+ ${_rows.length - 5} more rows',
                      style: AppTextStyles.caption,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _rows.isEmpty || _exporting
                      ? null
                      : () => _export(false),
                  child: const Text('Export CSV'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'Export PDF',
                  disabled: _rows.isEmpty || _exporting,
                  onPressed: _rows.isEmpty ? null : () => _export(true),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

class _ReportTable {
  const _ReportTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.type, required this.row});

  final ReportType type;
  final List<String> row;

  int? get _paymentStatusIndex {
    switch (type) {
      case ReportType.revenue:
      case ReportType.payments:
        return row.length - 1;
      case ReportType.appointments:
        return 6;
      case ReportType.clients:
      case ReportType.inventory:
      case ReportType.employees:
        return null;
    }
  }

  PaymentStatus? get _paymentStatus {
    final index = _paymentStatusIndex;
    if (index == null || index < 0 || index >= row.length) return null;
    for (final status in PaymentStatus.values) {
      if (status.name == row[index].toLowerCase()) return status;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final index = _paymentStatusIndex;
    final status = _paymentStatus;
    if (index == null || status == null) {
      return Text(row.join(' - '), style: AppTextStyles.bodySmall);
    }

    final beforeStatus = row.take(index).join(' - ');
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        Text('$beforeStatus -', style: AppTextStyles.bodySmall),
        PaymentStatusDot(status: status),
        Text(row[index], style: AppTextStyles.bodySmall),
      ],
    );
  }
}
