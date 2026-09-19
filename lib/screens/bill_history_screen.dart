import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../providers/app_providers.dart';
import '../services/csv_exporter.dart';
import '../theme/qt_theme.dart';
import '../widgets/qt_widgets.dart';
import '../widgets/pdf_preview_dialog.dart';

class BillHistoryScreen extends ConsumerStatefulWidget {
  const BillHistoryScreen({super.key});

  @override
  ConsumerState<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends ConsumerState<BillHistoryScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _taxFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final bills = ref.watch(billsProvider);
    final shop = ref.watch(shopProfileProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    final filteredBills = bills.where((b) {
      final q = _searchQuery.toLowerCase();
      final matchesQuery = b.invoiceNo.toLowerCase().contains(q) ||
          b.partyName.toLowerCase().contains(q) ||
          b.partyMobile.contains(q) ||
          b.partyState.toLowerCase().contains(q);

      final matchesStatus = _statusFilter == 'All' || b.paymentStatus == _statusFilter;

      final isIntra = b.totalIgst == 0;
      final matchesTax = _taxFilter == 'All' ||
          (_taxFilter == 'Intra-State' && isIntra) ||
          (_taxFilter == 'Inter-State' && !isIntra);

      return matchesQuery && matchesStatus && matchesTax;
    }).toList();

    double totalFilteredGrand = filteredBills.fold(0.0, (sum, b) => sum + b.grandTotal);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Toolbar with Overflow Protection
          QtCard(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search invoice #, customer, state...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: DropdownButtonFormField<String>(
                    value: _statusFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Status', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Statuses', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Paid', child: Text('Paid', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Partial', child: Text('Partial', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _statusFilter = val);
                    },
                  ),
                ),
                SizedBox(
                  width: 210,
                  child: DropdownButtonFormField<String>(
                    value: _taxFilter,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'GST Tax Type', isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Tax Types', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Intra-State', child: Text('Intra-State (CGST+SGST)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'Inter-State', child: Text('Inter-State (IGST)', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _taxFilter = val);
                    },
                  ),
                ),
                QtButton(
                  label: 'Export Invoices CSV',
                  icon: Icons.download,
                  onPressed: () {
                    final csv = CsvExporter.exportBillsToCsv(filteredBills);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Exported ${filteredBills.length} invoice records to CSV.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Invoices History Table Panel
          QtCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                QtPanelHeader(
                  title: 'Tax Invoices Archive (${filteredBills.length} matching | Total: ${currencyFormat.format(totalFilteredGrand)})',
                  icon: Icons.article,
                ),
                filteredBills.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No invoices match the selected search criteria.'),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 40,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 48,
                          columns: const [
                            DataColumn(label: Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('State', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Tax (CGST/SGST/IGST)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: filteredBills.map((bill) {
                            final isIntra = bill.totalIgst == 0;

                            return DataRow(
                              cells: [
                                DataCell(Text(bill.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataCell(Text(DateFormat('dd-MMM-yyyy').format(bill.date), style: const TextStyle(fontSize: 12))),
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(bill.partyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      if (bill.partyGstin != null)
                                        Text('GSTIN: ${bill.partyGstin}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  QtBadge(
                                    label: bill.partyState,
                                    color: isIntra ? QtColors.darkPrimary : QtColors.darkWarning,
                                  ),
                                ),
                                DataCell(Text(currencyFormat.format(bill.subtotal), style: const TextStyle(fontSize: 12))),
                                DataCell(
                                  isIntra
                                      ? Text('C+S: ${currencyFormat.format(bill.totalCgst + bill.totalSgst)}', style: const TextStyle(fontSize: 11, color: QtColors.darkPrimary))
                                      : Text('IGST: ${currencyFormat.format(bill.totalIgst)}', style: const TextStyle(fontSize: 11, color: QtColors.darkWarning)),
                                ),
                                DataCell(Text(currencyFormat.format(bill.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      DropdownButton<String>(
                                        value: bill.paymentStatus,
                                        underline: const SizedBox.shrink(),
                                        isDense: true,
                                        items: const [
                                          DropdownMenuItem(value: 'Paid', child: Text('Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: QtColors.darkSuccess))),
                                          DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: QtColors.darkError))),
                                          DropdownMenuItem(value: 'Partial', child: Text('Partial', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: QtColors.darkWarning))),
                                        ],
                                        onChanged: (val) {
                                          if (val != null) {
                                            ref.read(billsProvider.notifier).updatePaymentStatus(bill.id, val);
                                          }
                                        },
                                      ),
                                      if (bill.paymentStatus == 'Partial')
                                        Text('Paid: ${currencyFormat.format(bill.amountPaid)} | Due: ${currencyFormat.format(bill.balanceDue)}', style: const TextStyle(fontSize: 10, color: QtColors.darkWarning))
                                      else if (bill.paymentStatus == 'Unpaid')
                                        Text('Due: ${currencyFormat.format(bill.balanceDue)}', style: const TextStyle(fontSize: 10, color: QtColors.darkError))
                                      else
                                        Text('Paid: ${currencyFormat.format(bill.amountPaid)}', style: const TextStyle(fontSize: 10, color: QtColors.darkSuccess)),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  QtButton(
                                    label: 'PDF',
                                    icon: Icons.picture_as_pdf,
                                    onPressed: () => PdfPreviewDialog.show(context, bill, shop),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
