import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../models/party.dart';
import '../models/item.dart';

class CsvExporter {
  static String exportBillsToCsv(List<Bill> bills) {
    final StringBuffer buffer = StringBuffer();
    // Rainbow CSV Header (15 columns)
    buffer.writeln('id,invoiceNo,date,dueDate,partyId,partyName,partyState,subtotal,totalTax,grandTotal,paymentStatus,amountPaid,balanceDue,paymentDate,paymentMethod');

    final dateFormat = DateFormat('yyyy-MM-dd');

    for (final bill in bills) {
      buffer.writeln([
        _escapeCsv(bill.id),
        _escapeCsv(bill.invoiceNo),
        _escapeCsv(dateFormat.format(bill.date)),
        _escapeCsv(bill.dueDate != null ? dateFormat.format(bill.dueDate!) : ''),
        _escapeCsv(bill.partyId),
        _escapeCsv(bill.partyName),
        _escapeCsv(bill.partyState),
        bill.subtotal.toStringAsFixed(2),
        bill.totalTax.toStringAsFixed(2),
        bill.grandTotal.toStringAsFixed(2),
        _escapeCsv(bill.paymentStatus),
        bill.amountPaid.toStringAsFixed(2),
        bill.balanceDue.toStringAsFixed(2),
        _escapeCsv(bill.paymentDate != null ? dateFormat.format(bill.paymentDate!) : ''),
        _escapeCsv(bill.paymentMethod ?? ''),
      ].join(','));
    }

    return buffer.toString();
  }

  static String exportPartiesToCsv(List<Party> parties) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Party Name,Mobile,State,GSTIN,Email,Address');

    for (final party in parties) {
      buffer.writeln([
        _escapeCsv(party.name),
        _escapeCsv(party.mobile),
        _escapeCsv(party.state),
        _escapeCsv(party.gstin ?? 'N/A'),
        _escapeCsv(party.email ?? 'N/A'),
        _escapeCsv(party.address),
      ].join(','));
    }

    return buffer.toString();
  }

  static String exportItemsToCsv(List<Item> items) {
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('Item Name,HSN Code,Unit Price,GST %');

    for (final item in items) {
      buffer.writeln([
        _escapeCsv(item.name),
        _escapeCsv(item.hsnCode ?? 'N/A'),
        item.unitPrice.toStringAsFixed(2),
        '${item.gstPercent}%',
      ].join(','));
    }

    return buffer.toString();
  }

  static String _escapeCsv(String input) {
    if (input.contains(',') || input.contains('"') || input.contains('\n')) {
      final escaped = input.replaceAll('"', '""');
      return '"$escaped"';
    }
    return input;
  }
}
