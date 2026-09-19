import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/bill.dart';
import '../models/shop_profile.dart';
import 'number_to_words.dart';

class PdfInvoiceGenerator {
  static Future<Uint8List> generateInvoicePdf({
    required Bill bill,
    required ShopProfile shop,
  }) async {
    final pdf = pw.Document();

    final dateFormat = DateFormat('dd-MMM-yyyy');
    final formattedDate = dateFormat.format(bill.date);
    final isIntraState = bill.totalIgst == 0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        shop.name,
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(shop.address, style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('State: ${shop.state} | Phone: ${shop.phone}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('Email: ${shop.email}', style: const pw.TextStyle(fontSize: 9)),
                      pw.Text('GSTIN: ${shop.gstin}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.blue300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text('Invoice #: ${bill.invoiceNo}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: $formattedDate', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Payment Status: ${bill.paymentStatus}', style: pw.TextStyle(fontSize: 9, color: bill.paymentStatus == 'Paid' ? PdfColors.green800 : PdfColors.red800)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Divider(color: PdfColors.grey400, thickness: 1),
              pw.SizedBox(height: 8),

              // Billed To Section
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('BILLED TO (CUSTOMER DETAILS)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text(bill.partyName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Address: ${bill.partyAddress}', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('State: ${bill.partyState} | Mobile: ${bill.partyMobile}', style: const pw.TextStyle(fontSize: 9)),
                    if (bill.partyGstin != null && bill.partyGstin!.isNotEmpty)
                      pw.Text('GSTIN: ${bill.partyGstin}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Itemized Table
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                headers: [
                  '#',
                  'Item Name',
                  'HSN',
                  'Qty',
                  'Rate (Rs.)',
                  'Taxable (Rs.)',
                  'GST %',
                  if (isIntraState) 'CGST (Rs.)' else 'IGST (Rs.)',
                  if (isIntraState) 'SGST (Rs.)' else '',
                  'Total (Rs.)'
                ].where((h) => h.isNotEmpty).toList(),
                data: bill.items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final List<String> row = [
                    '$idx',
                    item.name,
                    item.hsnCode ?? '-',
                    '${item.qty}',
                    item.rate.toStringAsFixed(2),
                    item.taxableAmt.toStringAsFixed(2),
                    '${item.gstPercent.toStringAsFixed(0)}%',
                    if (isIntraState) item.cgst.toStringAsFixed(2) else item.igst.toStringAsFixed(2),
                    if (isIntraState) item.sgst.toStringAsFixed(2) else '',
                    item.lineTotal.toStringAsFixed(2),
                  ];
                  return row.where((c) => c.isNotEmpty).toList();
                }).toList(),
              ),

              pw.SizedBox(height: 12),

              // Summary Breakdown & Calculations
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Left side: Words & Bank info
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue50,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Amount in Words:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              pw.Text(
                                NumberToWords.convert(bill.grandTotal),
                                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text('Bank Details:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Bank: ${shop.bankName} | A/C: ${shop.accountNo}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('IFSC: ${shop.ifscCode}', style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 8),
                        pw.Text('Terms & Conditions:', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                        pw.Text(shop.terms, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),

                  // Right side: Totals summary box
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        children: [
                          _buildSummaryRow('Subtotal (Taxable):', 'Rs. ${bill.subtotal.toStringAsFixed(2)}'),
                          if (isIntraState) ...[
                            _buildSummaryRow('CGST Total:', 'Rs. ${bill.totalCgst.toStringAsFixed(2)}'),
                            _buildSummaryRow('SGST Total:', 'Rs. ${bill.totalSgst.toStringAsFixed(2)}'),
                          ] else ...[
                            _buildSummaryRow('IGST Total:', 'Rs. ${bill.totalIgst.toStringAsFixed(2)}'),
                          ],
                          _buildSummaryRow('Total Tax:', 'Rs. ${bill.totalTax.toStringAsFixed(2)}'),
                          if (bill.discount > 0)
                            _buildSummaryRow('Discount:', '- Rs. ${bill.discount.toStringAsFixed(2)}', color: PdfColors.red700),
                          pw.Divider(color: PdfColors.grey400),
                          _buildSummaryRow(
                            'Grand Total:',
                            'Rs. ${bill.grandTotal.toStringAsFixed(2)}',
                            isBold: true,
                            fontSize: 10,
                            color: PdfColors.blue900,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // Signature section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Customer Signature', style: const pw.TextStyle(fontSize: 8)),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('For ${shop.name}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 24),
                      pw.Text('Authorised Signatory', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 8,
    PdfColor color = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
