import 'package:flutter/services.dart' show rootBundle;
import '../models/party.dart';
import '../models/item.dart';
import '../models/bill.dart';

class CsvLoader {
  /// Simple robust CSV line parser supporting quoted values containing commas
  static List<List<String>> parseCsv(String input) {
    final List<List<String>> rows = [];
    final lines = input.split(RegExp(r'\r?\n'));

    for (final rawLine in lines) {
      if (rawLine.trim().isEmpty) continue;

      final List<String> fields = [];
      final StringBuffer currentField = StringBuffer();
      bool inQuotes = false;

      for (int i = 0; i < rawLine.length; i++) {
        final char = rawLine[i];

        if (char == '"') {
          if (inQuotes && i + 1 < rawLine.length && rawLine[i + 1] == '"') {
            currentField.write('"');
            i++;
          } else {
            inQuotes = !inQuotes;
          }
        } else if (char == ',' && !inQuotes) {
          fields.add(currentField.toString().trim());
          currentField.clear();
        } else {
          currentField.write(char);
        }
      }
      fields.add(currentField.toString().trim());
      rows.add(fields);
    }

    return rows;
  }

  /// Load parties from parties.csv string
  static List<Party> parseParties(String csvString) {
    final rows = parseCsv(csvString);
    if (rows.length <= 1) return [];

    final List<Party> parties = [];
    // Skip header row
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5) continue;

      final id = row[0];
      final name = row[1];
      final mobile = row[2];
      final address = row[3];
      final state = row[4];
      final gstin = row.length > 5 && row[5].isNotEmpty ? row[5] : null;
      final email = row.length > 6 && row[6].isNotEmpty ? row[6] : null;

      parties.add(Party(
        id: id,
        name: name,
        mobile: mobile,
        address: address,
        state: state,
        gstin: gstin,
        email: email,
      ));
    }
    return parties;
  }

  /// Load catalog items from items.csv string
  static List<Item> parseItems(String csvString) {
    final rows = parseCsv(csvString);
    if (rows.length <= 1) return [];

    final List<Item> items = [];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < 5) continue;

      final id = row[0];
      final name = row[1];
      final hsnCode = row[2].isNotEmpty ? row[2] : null;
      final unitPrice = double.tryParse(row[3]) ?? 0.0;
      final gstPercent = double.tryParse(row[4]) ?? 18.0;

      items.add(Item(
        id: id,
        name: name,
        hsnCode: hsnCode,
        unitPrice: unitPrice,
        gstPercent: gstPercent,
      ));
    }
    return items;
  }

  /// Load bills and their line items from bills.csv and bill_items.csv strings
  static List<Bill> parseBills({
    required String billsCsv,
    required String billItemsCsv,
    required List<Party> parties,
  }) {
    final billRows = parseCsv(billsCsv);
    final itemRows = parseCsv(billItemsCsv);

    if (billRows.length <= 1) return [];

    // Group bill items by billId
    final Map<String, List<BillItem>> billItemsMap = {};

    for (int i = 1; i < itemRows.length; i++) {
      final row = itemRows[i];
      if (row.length < 11) continue;

      final billId = row[0];
      final itemId = row[1];
      final name = row[2];
      final qty = int.tryParse(row[3]) ?? 1;
      final rate = double.tryParse(row[4]) ?? 0.0;
      final gstPercent = double.tryParse(row[5]) ?? 18.0;
      final taxableAmt = double.tryParse(row[6]) ?? 0.0;
      final cgst = double.tryParse(row[7]) ?? 0.0;
      final sgst = double.tryParse(row[8]) ?? 0.0;
      final igst = double.tryParse(row[9]) ?? 0.0;

      final billItem = BillItem(
        itemId: itemId,
        name: name,
        qty: qty,
        rate: rate,
        gstPercent: gstPercent,
        taxableAmt: taxableAmt,
        cgst: cgst,
        sgst: sgst,
        igst: igst,
      );

      billItemsMap.putIfAbsent(billId, () => []).add(billItem);
    }

    final Map<String, Party> partyMap = {for (final p in parties) p.id: p};
    final List<Bill> bills = [];

    for (int i = 1; i < billRows.length; i++) {
      final row = billRows[i];
      if (row.length < 9) continue;

      final bool isFullFormat = row.length >= 11;

      final id = row[0];
      final invoiceNo = row[1];
      final date = DateTime.tryParse(row[2]) ?? DateTime.now();
      final DateTime? dueDate = isFullFormat ? DateTime.tryParse(row[3]) : null;
      final partyId = isFullFormat ? row[4] : row[3];
      final partyName = isFullFormat ? row[5] : row[4];
      final partyState = isFullFormat ? row[6] : row[5];
      final subtotal = double.tryParse(isFullFormat ? row[7] : row[6]) ?? 0.0;
      final totalTax = double.tryParse(isFullFormat ? row[8] : row[7]) ?? 0.0;
      final grandTotal = double.tryParse(isFullFormat ? row[9] : row[8]) ?? 0.0;
      final paymentStatus = isFullFormat && row[10].isNotEmpty ? row[10] : 'Paid';
      final double? amountPaid = isFullFormat && row.length > 11 ? double.tryParse(row[11]) : null;
      final double? balanceDue = isFullFormat && row.length > 12 ? double.tryParse(row[12]) : null;
      final DateTime? paymentDate = isFullFormat && row.length > 13 ? DateTime.tryParse(row[13]) : null;
      final String? paymentMethod = isFullFormat && row.length > 14 && row[14].isNotEmpty ? row[14] : null;

      final matchedParty = partyMap[partyId];
      final items = billItemsMap[id] ?? [];

      // Determine CGST, SGST, IGST totals
      double totalCgst = 0.0;
      double totalSgst = 0.0;
      double totalIgst = 0.0;

      for (final item in items) {
        totalCgst += item.cgst;
        totalSgst += item.sgst;
        totalIgst += item.igst;
      }

      bills.add(Bill(
        id: id,
        invoiceNo: invoiceNo,
        date: date,
        dueDate: dueDate,
        partyId: partyId,
        partyName: partyName,
        partyState: partyState,
        partyGstin: matchedParty?.gstin,
        partyAddress: matchedParty?.address ?? 'Customer Address',
        partyMobile: matchedParty?.mobile ?? 'N/A',
        items: items,
        subtotal: subtotal,
        totalCgst: totalCgst,
        totalSgst: totalSgst,
        totalIgst: totalIgst,
        totalTax: totalTax,
        grandTotal: grandTotal,
        paymentStatus: paymentStatus,
        amountPaid: amountPaid,
        balanceDue: balanceDue,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
      ));
    }

    return bills;
  }

  /// Load fake CSV data from asset files automatically
  static Future<Map<String, dynamic>?> loadFakeDataFromAssets() async {
    try {
      final partiesStr = await rootBundle.loadString('asset/parties.csv');
      final itemsStr = await rootBundle.loadString('asset/items.csv');
      final billsStr = await rootBundle.loadString('asset/bills.csv');
      final billItemsStr = await rootBundle.loadString('asset/bill_items.csv');

      final parties = parseParties(partiesStr);
      final items = parseItems(itemsStr);
      final bills = parseBills(
        billsCsv: billsStr,
        billItemsCsv: billItemsStr,
        parties: parties,
      );

      return {
        'parties': parties,
        'items': items,
        'bills': bills,
      };
    } catch (e) {
      return null;
    }
  }
}
