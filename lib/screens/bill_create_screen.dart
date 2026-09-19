import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/party.dart';
import '../models/item.dart';
import '../models/bill.dart';
import '../providers/app_providers.dart';
import '../services/ai_assistant_service.dart';
import '../services/gst_calculator.dart';
import '../services/invoice_number_generator.dart';
import '../theme/qt_theme.dart';
import '../widgets/qt_widgets.dart';
import '../widgets/pdf_preview_dialog.dart';
import '../widgets/ai_quick_draft_modal.dart';

class BillCreateScreen extends ConsumerStatefulWidget {
  const BillCreateScreen({super.key});

  @override
  ConsumerState<BillCreateScreen> createState() => _BillCreateScreenState();
}

class _BillCreateScreenState extends ConsumerState<BillCreateScreen> {
  Party? _selectedParty;
  DateTime _invoiceDate = DateTime.now();
  String _paymentStatus = 'Paid';
  double _discount = 0.0;
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController(text: '0');

  // Draft line items list
  final List<BillItem> _lineItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final parties = ref.read(partiesProvider);
      if (parties.isNotEmpty && _selectedParty == null) {
        setState(() => _selectedParty = parties.first);
      }
    });
  }

  void _recalculateAllLines() {
    if (_selectedParty == null) return;
    final shop = ref.read(shopProfileProvider);

    setState(() {
      for (int i = 0; i < _lineItems.length; i++) {
        final item = _lineItems[i];
        _lineItems[i] = GstCalculator.calculateLineItem(
          itemId: item.itemId,
          name: item.name,
          hsnCode: item.hsnCode,
          qty: item.qty,
          rate: item.rate,
          gstPercent: item.gstPercent,
          partyState: _selectedParty!.state,
          shopState: shop.state,
        );
      }
    });
  }

  void _addLineItem(Item catalogItem) {
    if (_selectedParty == null) return;
    final shop = ref.read(shopProfileProvider);

    final lineItem = GstCalculator.calculateLineItem(
      itemId: catalogItem.id,
      name: catalogItem.name,
      hsnCode: catalogItem.hsnCode,
      qty: 1,
      rate: catalogItem.unitPrice,
      gstPercent: catalogItem.gstPercent,
      partyState: _selectedParty!.state,
      shopState: shop.state,
    );

    setState(() {
      _lineItems.add(lineItem);
    });
  }

  void _openAiDraftModal() async {
    final result = await AiQuickDraftModal.show(context);
    if (result != null) {
      setState(() {
        if (result.party != null) {
          _selectedParty = result.party;
        }
        if (result.lineItems.isNotEmpty) {
          _lineItems.clear();
          _lineItems.addAll(result.lineItems);
        }
      });
      _recalculateAllLines();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✨ ${result.rawSummary}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final parties = ref.watch(partiesProvider);
    final items = ref.watch(itemsProvider);
    final bills = ref.watch(billsProvider);
    final shop = ref.watch(shopProfileProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    // Auto generate next invoice number
    final String invoiceNo = InvoiceNumberGenerator.generate(bills.length);

    // Tax type indicator
    final bool isIntraState = _selectedParty != null &&
        _selectedParty!.state.trim().toLowerCase() == shop.state.trim().toLowerCase();

    // Calculate totals live
    final totals = GstCalculator.calculateBillTotals(
      items: _lineItems,
      discount: _discount,
    );

    // Live AI Anomaly & Duplicate Checks
    final anomalies = AiAssistantService.detectBillAnomalies(
      items: _lineItems,
      party: _selectedParty,
      discount: _discount,
      existingBills: bills,
    );

    final Widget partyAndItemsWidget = Column(
      children: [
        // Party & Invoice Details Card
        QtCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              QtPanelHeader(
                title: 'Invoice & Customer Header',
                icon: Icons.assignment_ind,
                actions: [
                  QtButton(
                    label: '✨ AI QUICK DRAFT',
                    icon: Icons.auto_awesome,
                    isPrimary: true,
                    onPressed: _openAiDraftModal,
                  ),
                  const SizedBox(width: 8),
                  QtBadge(
                    label: 'Invoice #: $invoiceNo',
                    color: QtColors.darkPrimary,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isWide = constraints.maxWidth > 550;
                        if (isWide) {
                          return Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: DropdownButtonFormField<Party>(
                                  value: _selectedParty,
                                  isExpanded: true,
                                  decoration: const InputDecoration(labelText: 'Select Customer (Billed To) *'),
                                  items: parties.map((p) {
                                    return DropdownMenuItem(
                                      value: p,
                                      child: Text('${p.name} (${p.state})', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (p) {
                                    setState(() => _selectedParty = p);
                                    _recalculateAllLines();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 4,
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _invoiceDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setState(() => _invoiceDate = picked);
                                    }
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(
                                      labelText: 'Invoice Date',
                                      suffixIcon: Icon(Icons.calendar_today, size: 16),
                                    ),
                                    child: Text(
                                      DateFormat('dd-MMM-yyyy').format(_invoiceDate),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            DropdownButtonFormField<Party>(
                              value: _selectedParty,
                              isExpanded: true,
                              decoration: const InputDecoration(labelText: 'Select Customer (Billed To) *'),
                              items: parties.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Text('${p.name} (${p.state})', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (p) {
                                setState(() => _selectedParty = p);
                                _recalculateAllLines();
                              },
                            ),
                            const SizedBox(height: 12),
                            InkWell(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _invoiceDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() => _invoiceDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Invoice Date',
                                  suffixIcon: Icon(Icons.calendar_today, size: 16),
                                ),
                                child: Text(
                                  DateFormat('dd-MMM-yyyy').format(_invoiceDate),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (_selectedParty != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? QtColors.darkHeader : QtColors.lightHeader,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Address: ${_selectedParty!.address}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                Text(
                                  'Mobile: ${_selectedParty!.mobile} | GSTIN: ${_selectedParty!.gstin ?? "Unregistered"}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            QtBadge(
                              label: isIntraState ? 'INTRA-STATE (CGST + SGST)' : 'INTER-STATE (IGST)',
                              color: isIntraState ? QtColors.darkSuccess : QtColors.darkWarning,
                              icon: isIntraState ? Icons.home : Icons.flight_takeoff,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Add Line Item Card
        QtCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              QtPanelHeader(
                title: 'Line Items (${_lineItems.length} items added)',
                icon: Icons.list_alt,
                actions: [
                  PopupMenuButton<Item>(
                    tooltip: 'Add item from catalog',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: QtColors.darkAccent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Add Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                    itemBuilder: (context) {
                      return items.map((catItem) {
                        return PopupMenuItem(
                          value: catItem,
                          child: Row(
                            children: [
                              Text(catItem.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text('₹${catItem.unitPrice} (${catItem.gstPercent.toStringAsFixed(0)}% GST)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    onSelected: (catItem) => _addLineItem(catItem),
                  ),
                ],
              ),
              _lineItems.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No line items added yet. Click "Add Item" above or use "✨ AI Quick Draft".'),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingRowHeight: 38,
                        dataRowMinHeight: 48,
                        dataRowMaxHeight: 48,
                        columns: [
                          const DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          const DataColumn(label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          const DataColumn(label: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          const DataColumn(label: Text('Rate (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          const DataColumn(label: Text('Taxable (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          const DataColumn(label: Text('GST %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          if (isIntraState) const DataColumn(label: Text('CGST+SGST (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          if (!isIntraState) const DataColumn(label: Text('IGST (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          const DataColumn(label: Text('Total (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          const DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                        rows: _lineItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;

                          return DataRow(
                            cells: [
                              DataCell(Text('${index + 1}')),
                              DataCell(
                                SizedBox(
                                  width: 160,
                                  child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 70,
                                  child: TextFormField(
                                    initialValue: '${item.qty}',
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
                                    onChanged: (val) {
                                      final newQty = int.tryParse(val) ?? 1;
                                      if (newQty > 0) {
                                        final shop = ref.read(shopProfileProvider);
                                        setState(() {
                                          _lineItems[index] = GstCalculator.calculateLineItem(
                                            itemId: item.itemId,
                                            name: item.name,
                                            hsnCode: item.hsnCode,
                                            qty: newQty,
                                            rate: item.rate,
                                            gstPercent: item.gstPercent,
                                            partyState: _selectedParty!.state,
                                            shopState: shop.state,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: 90,
                                  child: TextFormField(
                                    initialValue: '${item.rate}',
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4)),
                                    onChanged: (val) {
                                      final newRate = double.tryParse(val) ?? item.rate;
                                      final shop = ref.read(shopProfileProvider);
                                      setState(() {
                                        _lineItems[index] = GstCalculator.calculateLineItem(
                                          itemId: item.itemId,
                                          name: item.name,
                                          hsnCode: item.hsnCode,
                                          qty: item.qty,
                                          rate: newRate,
                                          gstPercent: item.gstPercent,
                                          partyState: _selectedParty!.state,
                                          shopState: shop.state,
                                        );
                                      });
                                    },
                                  ),
                                ),
                              ),
                              DataCell(Text(currencyFormat.format(item.taxableAmt), style: const TextStyle(fontSize: 12))),
                              DataCell(Text('${item.gstPercent.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12))),
                              if (isIntraState)
                                DataCell(Text('${currencyFormat.format(item.cgst)} + ${currencyFormat.format(item.sgst)}', style: const TextStyle(fontSize: 11, color: QtColors.darkPrimary))),
                              if (!isIntraState)
                                DataCell(Text(currencyFormat.format(item.igst), style: const TextStyle(fontSize: 11, color: QtColors.darkWarning))),
                              DataCell(Text(currencyFormat.format(item.lineTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete, color: QtColors.darkError, size: 18),
                                  onPressed: () {
                                    setState(() => _lineItems.removeAt(index));
                                  },
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
    );

    final Widget totalsSummaryWidget = Column(
      children: [
        // AI Anomaly & Duplicate Shield Status Card
        QtCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    anomalies.isEmpty ? Icons.verified_user : Icons.warning_amber_rounded,
                    color: anomalies.isEmpty ? QtColors.darkSuccess : QtColors.darkWarning,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '✨ AI FRAUD & TYPO SHIELD',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                      color: anomalies.isEmpty ? QtColors.darkSuccess : QtColors.darkWarning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              anomalies.isEmpty
                  ? const Text(
                      '✅ No rate anomalies or duplicate bill warnings detected.',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: anomalies.map((anom) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '⚠️ ${anom.title}: ${anom.description}',
                            style: const TextStyle(fontSize: 11, color: QtColors.darkWarning),
                          ),
                        );
                      }).toList(),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Calculations Card
        QtCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              const QtPanelHeader(
                title: 'Bill Calculation Summary',
                icon: Icons.calculate,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCalculationRow('Subtotal (Taxable):', currencyFormat.format(totals.subtotal)),
                    if (isIntraState) ...[
                      _buildCalculationRow('CGST:', currencyFormat.format(totals.totalCgst), color: QtColors.darkPrimary),
                      _buildCalculationRow('SGST:', currencyFormat.format(totals.totalSgst), color: QtColors.darkPrimary),
                    ] else ...[
                      _buildCalculationRow('IGST:', currencyFormat.format(totals.totalIgst), color: QtColors.darkWarning),
                    ],
                    _buildCalculationRow('Total Tax:', currencyFormat.format(totals.totalTax)),
                    const Divider(height: 16),

                    // Discount Input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount (₹):', style: TextStyle(fontSize: 12)),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            controller: _discountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                            onChanged: (val) {
                              setState(() {
                                _discount = double.tryParse(val) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Grand Total Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: QtColors.darkAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: QtColors.darkAccent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('GRAND TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(
                            currencyFormat.format(totals.grandTotal),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: QtColors.darkSuccess),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Payment Status Dropdown
                    DropdownButtonFormField<String>(
                      value: _paymentStatus,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Payment Status'),
                      items: const [
                        DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                        DropdownMenuItem(value: 'Unpaid', child: Text('Unpaid')),
                        DropdownMenuItem(value: 'Partial', child: Text('Partial')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _paymentStatus = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Remarks (Optional)',
                        hintText: 'e.g. Delivered via Express Courier',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save & Generate PDF Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: QtButton(
                        label: 'SAVE BILL & PRINT PDF',
                        icon: Icons.picture_as_pdf,
                        isPrimary: true,
                        onPressed: _lineItems.isEmpty || _selectedParty == null
                            ? null
                            : () => _saveAndPreviewBill(context, invoiceNo, totals),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notice Banner: Immutable Legal Record
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.amber.withOpacity(0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'NOTICE: Saved bills are immutable legal financial records. Verify customer details and quantities carefully before saving.',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Responsive Layout Builder
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: partyAndItemsWidget),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: totalsSummaryWidget),
                  ],
                );
              }
              return Column(
                children: [
                  partyAndItemsWidget,
                  const SizedBox(height: 16),
                  totalsSummaryWidget,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _saveAndPreviewBill(BuildContext context, String invoiceNo, GstCalculationResult totals) {
    if (_selectedParty == null || _lineItems.isEmpty) return;
    final shop = ref.read(shopProfileProvider);

    final newBill = Bill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      invoiceNo: invoiceNo,
      date: _invoiceDate,
      partyId: _selectedParty!.id,
      partyName: _selectedParty!.name,
      partyState: _selectedParty!.state,
      partyGstin: _selectedParty!.gstin,
      partyAddress: _selectedParty!.address,
      partyMobile: _selectedParty!.mobile,
      items: List.from(_lineItems),
      subtotal: totals.subtotal,
      totalCgst: totals.totalCgst,
      totalSgst: totals.totalSgst,
      totalIgst: totals.totalIgst,
      totalTax: totals.totalTax,
      discount: totals.discount,
      grandTotal: totals.grandTotal,
      paymentStatus: _paymentStatus,
      notes: _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
    );

    // Add immutable bill to state repository
    ref.read(billsProvider.notifier).addBill(newBill);

    // Show PDF Modal Preview directly
    PdfPreviewDialog.show(context, newBill, shop);

    // Clear form
    setState(() {
      _lineItems.clear();
      _discount = 0.0;
      _discountCtrl.text = '0';
      _notesCtrl.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bill ${newBill.invoiceNo} saved successfully!')),
    );
  }
}
