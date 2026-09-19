import '../models/item.dart';
import '../models/bill.dart';

class GstCalculationResult {
  final List<BillItem> items;
  final double subtotal;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double totalTax;
  final double discount;
  final double grandTotal;

  const GstCalculationResult({
    required this.items,
    required this.subtotal,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalIgst,
    required this.totalTax,
    required this.discount,
    required this.grandTotal,
  });
}

class GstCalculator {
  /// Round monetary values to 2 decimal places accurately
  static double round2(double val) {
    return (val * 100).roundToDouble() / 100;
  }

  /// Calculates GST for a single line item
  static BillItem calculateLineItem({
    required String itemId,
    required String name,
    String? hsnCode,
    required int qty,
    required double rate,
    required double gstPercent,
    required String partyState,
    required String shopState,
  }) {
    final double taxableAmt = round2(rate * qty);
    final bool isIntraState = partyState.trim().toLowerCase() == shopState.trim().toLowerCase();

    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;

    if (isIntraState) {
      final double halfPercent = gstPercent / 2.0;
      cgst = round2(taxableAmt * (halfPercent / 100.0));
      sgst = round2(taxableAmt * (halfPercent / 100.0));
      igst = 0.0;
    } else {
      igst = round2(taxableAmt * (gstPercent / 100.0));
      cgst = 0.0;
      sgst = 0.0;
    }

    return BillItem(
      itemId: itemId,
      name: name,
      hsnCode: hsnCode,
      qty: qty,
      rate: rate,
      gstPercent: gstPercent,
      taxableAmt: taxableAmt,
      cgst: cgst,
      sgst: sgst,
      igst: igst,
    );
  }

  /// Calculates totals across a list of BillItems
  static GstCalculationResult calculateBillTotals({
    required List<BillItem> items,
    double discount = 0.0,
  }) {
    double subtotal = 0.0;
    double totalCgst = 0.0;
    double totalSgst = 0.0;
    double totalIgst = 0.0;

    for (final item in items) {
      subtotal += item.taxableAmt;
      totalCgst += item.cgst;
      totalSgst += item.sgst;
      totalIgst += item.igst;
    }

    subtotal = round2(subtotal);
    totalCgst = round2(totalCgst);
    totalSgst = round2(totalSgst);
    totalIgst = round2(totalIgst);

    final double totalTax = round2(totalCgst + totalSgst + totalIgst);
    final double rawGrandTotal = subtotal + totalTax - discount;
    final double grandTotal = round2(rawGrandTotal < 0 ? 0.0 : rawGrandTotal);

    return GstCalculationResult(
      items: items,
      subtotal: subtotal,
      totalCgst: totalCgst,
      totalSgst: totalSgst,
      totalIgst: totalIgst,
      totalTax: totalTax,
      discount: discount,
      grandTotal: grandTotal,
    );
  }
}
