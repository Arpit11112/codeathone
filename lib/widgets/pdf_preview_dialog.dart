import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../models/bill.dart';
import '../models/shop_profile.dart';
import '../services/pdf_generator.dart';
import '../theme/qt_theme.dart';

class PdfPreviewDialog extends StatelessWidget {
  final Bill bill;
  final ShopProfile shop;

  const PdfPreviewDialog({
    super.key,
    required this.bill,
    required this.shop,
  });

  static Future<void> show(BuildContext context, Bill bill, ShopProfile shop) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => PdfPreviewDialog(bill: bill, shop: shop),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? QtColors.darkSurface : QtColors.lightSurface;
    final headerBg = isDark ? QtColors.darkHeader : QtColors.lightHeader;
    final borderColor = isDark ? QtColors.darkBorder : QtColors.lightBorder;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: borderColor, width: 1),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      child: SizedBox(
        width: 900,
        height: 700,
        child: Column(
          children: [
            // Qt Window Title Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: headerBg,
                border: Border(bottom: BorderSide(color: borderColor, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, size: 20, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Text(
                    'INVOICE PREVIEW & PRINT - ${bill.invoiceNo}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                      color: isDark ? QtColors.darkTextPrimary : QtColors.lightTextPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // PDF Preview Body
            Expanded(
              child: PdfPreview(
                build: (format) => PdfInvoiceGenerator.generateInvoicePdf(bill: bill, shop: shop),
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                maxPageWidth: 700,
                pdfFileName: 'Invoice_${bill.invoiceNo}.pdf',
                previewPageMargin: const EdgeInsets.all(16),
                loadingWidget: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
