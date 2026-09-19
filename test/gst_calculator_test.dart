import 'package:flutter_test/flutter_test.dart';
import 'package:codeathone/services/gst_calculator.dart';
import 'package:codeathone/models/bill.dart';

void main() {
  group('GstCalculator Tests', () {
    test('Intra-state calculation (Same State: Maharashtra & Maharashtra)', () {
      final item = GstCalculator.calculateLineItem(
        itemId: '1',
        name: 'Wireless Mouse',
        qty: 2,
        rate: 500.0,
        gstPercent: 18.0,
        partyState: 'Maharashtra',
        shopState: 'Maharashtra',
      );

      expect(item.taxableAmt, equals(1000.0));
      expect(item.cgst, equals(90.0)); // 9% of 1000
      expect(item.sgst, equals(90.0)); // 9% of 1000
      expect(item.igst, equals(0.0));
      expect(item.lineTotal, equals(1180.0));
    });

    test('Inter-state calculation (Different State: Maharashtra & Karnataka)', () {
      final item = GstCalculator.calculateLineItem(
        itemId: '2',
        name: 'Mechanical Keyboard',
        qty: 1,
        rate: 2500.0,
        gstPercent: 18.0,
        partyState: 'Karnataka',
        shopState: 'Maharashtra',
      );

      expect(item.taxableAmt, equals(2500.0));
      expect(item.cgst, equals(0.0));
      expect(item.sgst, equals(0.0));
      expect(item.igst, equals(450.0)); // 18% of 2500
      expect(item.lineTotal, equals(2950.0));
    });

    test('Bill totals calculation with discount', () {
      final item1 = GstCalculator.calculateLineItem(
        itemId: '1',
        name: 'Item 1',
        qty: 1,
        rate: 1000.0,
        gstPercent: 18.0,
        partyState: 'Gujarat',
        shopState: 'Gujarat',
      );

      final item2 = GstCalculator.calculateLineItem(
        itemId: '2',
        name: 'Item 2',
        qty: 2,
        rate: 500.0,
        gstPercent: 12.0,
        partyState: 'Gujarat',
        shopState: 'Gujarat',
      );

      final totals = GstCalculator.calculateBillTotals(
        items: [item1, item2],
        discount: 100.0,
      );

      expect(totals.subtotal, equals(2000.0));
      expect(totals.totalCgst, equals(150.0)); // 90 + 60
      expect(totals.totalSgst, equals(150.0)); // 90 + 60
      expect(totals.totalIgst, equals(0.0));
      expect(totals.totalTax, equals(300.0));
      expect(totals.grandTotal, equals(2200.0)); // 2000 + 300 - 100
    });
  });
}
