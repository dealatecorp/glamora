import 'dart:io';
import 'dart:typed_data';

import '../../../data/repositories/repositories.dart';
import '../../../models/salon_models.dart';

class RevenueFilter {
  const RevenueFilter({
    this.start,
    this.end,
    this.employeeId,
    this.serviceId,
    this.category,
    this.method,
    this.status,
  });
  final DateTime? start;
  final DateTime? end;
  final String? employeeId;
  final String? serviceId;
  final ServiceCategory? category;
  final PaymentMethod? method;
  final PaymentStatus? status;
  bool includes(DateTime date) =>
      (start == null ||
          !date.isBefore(DateTime(start!.year, start!.month, start!.day))) &&
      (end == null ||
          !date.isAfter(DateTime(end!.year, end!.month, end!.day, 23, 59, 59)));
}

class RevenueRecord {
  const RevenueRecord({
    required this.invoice,
    required this.appointment,
    this.payment,
  });
  final Invoice invoice;
  final Appointment appointment;
  final Payment? payment;
  double get billed => invoice.total;
  double get received =>
      payment?.status == PaymentStatus.paid ? payment!.amount : 0;
  double get refunded =>
      payment?.status == PaymentStatus.refunded ? payment!.amount : 0;
  double get pending =>
      payment?.status == PaymentStatus.pending || payment == null
      ? invoice.balance
      : 0;
}

class RevenueSummary {
  const RevenueSummary(this.records);
  final List<RevenueRecord> records;
  double get billed => records.fold(0, (sum, item) => sum + item.billed);
  double get received => records.fold(0, (sum, item) => sum + item.received);
  double get pending => records.fold(0, (sum, item) => sum + item.pending);
  double get refunded => records.fold(0, (sum, item) => sum + item.refunded);
}

class RevenueService {
  RevenueService(this.repository);
  final DemoRepository repository;
  Future<RevenueSummary> summary([
    RevenueFilter filter = const RevenueFilter(),
  ]) async {
    final results = await Future.wait([
      repository.getInvoices(),
      repository.getPayments(),
      repository.getAppointments(),
    ]);
    final invoices = results[0] as List<Invoice>;
    final payments = results[1] as List<Payment>;
    final appointments = results[2] as List<Appointment>;
    final appointmentById = {for (final value in appointments) value.id: value};
    final paymentByInvoice = {
      for (final value in payments) value.invoiceId: value,
    };
    final records = <RevenueRecord>[];
    for (final invoice in invoices) {
      final appointment = appointmentById[invoice.appointmentId];
      if (appointment == null ||
          appointment.status != AppointmentStatus.completed ||
          !filter.includes(invoice.issuedAt))
        continue;
      final payment = paymentByInvoice[invoice.id];
      final services = appointment.services;
      if (filter.employeeId != null &&
          !services.any((item) => item.employeeId == filter.employeeId))
        continue;
      if (filter.serviceId != null &&
          !services.any((item) => item.serviceId == filter.serviceId))
        continue;
      if (filter.category != null &&
          !services.any((item) => item.category == filter.category))
        continue;
      if (filter.method != null && payment?.method != filter.method) continue;
      if (filter.status != null &&
          (payment?.status ?? PaymentStatus.pending) != filter.status)
        continue;
      records.add(
        RevenueRecord(
          invoice: invoice,
          appointment: appointment,
          payment: payment,
        ),
      );
    }
    records.sort((a, b) => b.invoice.issuedAt.compareTo(a.invoice.issuedAt));
    return RevenueSummary(records);
  }
}

class ReportExportService {
  Future<File> exportCsv({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    String cell(String value) => '"${value.replaceAll('"', '""')}"';
    final body = <String>[
      '$title\nGenerated: ${DateTime.now().toLocal()}\n',
      headers.map(cell).join(', '),
      ...rows.map((row) => row.map(cell).join(', ')),
    ].join('\n');
    final file = File(
      '${Directory.systemTemp.path}/glamora_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    return file.writeAsString(body);
  }

  Future<File> exportPdf({
    required String title,
    required List<String> lines,
  }) async {
    String safeText(String value) {
      final ascii = value.codeUnits
          .map(
            (code) =>
                code >= 32 && code <= 126 ? String.fromCharCode(code) : '?',
          )
          .join();
      return ascii
          .replaceAll('\\', '\\\\')
          .replaceAll('(', '\\(')
          .replaceAll(')', '\\)');
    }

    final safe = [title, ...lines].map(safeText).join('\n');
    final stream =
        'BT /F1 10 Tf 40 760 Td 12 TL (${safe.replaceAll('\n', ') Tj T* (')}) Tj ET';
    final objects = [
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
      '<< /Length ${stream.length} >>\nstream\n$stream\nendstream',
    ];
    var output = '%PDF-1.4\n';
    final offsets = <int>[0];
    for (var i = 0; i < objects.length; i++) {
      offsets.add(output.length);
      output += '${i + 1} 0 obj\n${objects[i]}\nendobj\n';
    }
    final xref = output.length;
    output +=
        'xref\n0 ${objects.length + 1}\n0000000000 65535 f \n${offsets.skip(1).map((offset) => '${offset.toString().padLeft(10, '0')} 00000 n ').join('\n')}\ntrailer << /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF';
    final file = File(
      '${Directory.systemTemp.path}/glamora_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    return file.writeAsBytes(Uint8List.fromList(output.codeUnits));
  }
}
