import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/party.dart';
import '../models/bill.dart';
import '../providers/app_providers.dart';
import '../services/csv_exporter.dart';
import '../theme/qt_theme.dart';
import '../widgets/qt_widgets.dart';
import '../widgets/pdf_preview_dialog.dart';

const List<String> indianStates = [
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
  'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
  'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
  'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
  'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
  'Delhi', 'Jammu & Kashmir', 'Ladakh'
];

class PartyScreen extends ConsumerStatefulWidget {
  const PartyScreen({super.key});

  @override
  ConsumerState<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends ConsumerState<PartyScreen> {
  String _searchQuery = '';
  Party? _selectedPartyForHistory;

  @override
  Widget build(BuildContext context) {
    final parties = ref.watch(partiesProvider);
    final bills = ref.watch(billsProvider);
    final shop = ref.watch(shopProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredParties = parties.where((p) {
      final q = _searchQuery.toLowerCase();
      return p.name.toLowerCase().contains(q) ||
          p.mobile.contains(q) ||
          p.state.toLowerCase().contains(q) ||
          (p.gstin?.toLowerCase().contains(q) ?? false);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar & Controls
          QtCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search customer by name, mobile, state, or GSTIN...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                QtButton(
                  label: 'Add Customer',
                  icon: Icons.person_add,
                  isPrimary: true,
                  onPressed: () => _showAddEditPartyDialog(context),
                ),
                const SizedBox(width: 8),
                QtButton(
                  label: 'Export CSV',
                  icon: Icons.download,
                  onPressed: () {
                    final csv = CsvExporter.exportPartiesToCsv(parties);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Exported ${parties.length} customer records to CSV.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Parties Table Panel
          QtCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                QtPanelHeader(
                  title: 'Customer Directory (${filteredParties.length} registered)',
                  icon: Icons.people,
                ),
                filteredParties.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No customers found.'),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 40,
                          dataRowMinHeight: 46,
                          dataRowMaxHeight: 46,
                          columns: const [
                            DataColumn(label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('State', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('GSTIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: filteredParties.map((party) {
                            final isSameState = party.state.trim().toLowerCase() == shop.state.trim().toLowerCase();
                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(party.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      if (party.email != null && party.email!.isNotEmpty)
                                        Text(party.email!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                DataCell(Text(party.mobile, style: const TextStyle(fontSize: 12))),
                                DataCell(
                                  QtBadge(
                                    label: party.state,
                                    color: isSameState ? QtColors.darkPrimary : QtColors.darkWarning,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    party.gstin ?? 'Unregistered (URP)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: party.gstin != null ? FontWeight.bold : FontWeight.normal,
                                      color: party.gstin != null ? (isDark ? QtColors.darkSuccess : QtColors.lightSuccess) : Colors.grey,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      party.address,
                                      style: const TextStyle(fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.receipt_long, size: 18, color: QtColors.darkPrimary),
                                        tooltip: 'View Party Bill History',
                                        onPressed: () => setState(() => _selectedPartyForHistory = party),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: Colors.amber),
                                        tooltip: 'Edit Customer',
                                        onPressed: () => _showAddEditPartyDialog(context, party: party),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: QtColors.darkError),
                                        tooltip: 'Delete Customer',
                                        onPressed: () => _confirmDeleteParty(context, party),
                                      ),
                                    ],
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

          // Party Specific Bill History Panel (if selected)
          if (_selectedPartyForHistory != null) ...[
            const SizedBox(height: 20),
            _buildPartyBillHistoryPanel(context, _selectedPartyForHistory!, bills, shop),
          ],
        ],
      ),
    );
  }

  Widget _buildPartyBillHistoryPanel(BuildContext context, Party party, List<Bill> allBills, shop) {
    final partyBills = allBills.where((b) => b.partyId == party.id).toList();
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    return QtCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          QtPanelHeader(
            title: 'Bill History for ${party.name} (${partyBills.length} Bills)',
            icon: Icons.history_edu,
            actions: [
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _selectedPartyForHistory = null),
              ),
            ],
          ),
          partyBills.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No past bills recorded for this customer.'),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 38,
                    dataRowMinHeight: 44,
                    dataRowMaxHeight: 44,
                    columns: const [
                      DataColumn(label: Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Tax', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      DataColumn(label: Text('PDF Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    ],
                    rows: partyBills.map((bill) {
                      return DataRow(
                        cells: [
                          DataCell(Text(bill.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataCell(Text(DateFormat('dd-MMM-yyyy').format(bill.date), style: const TextStyle(fontSize: 12))),
                          DataCell(Text(currencyFormat.format(bill.subtotal), style: const TextStyle(fontSize: 12))),
                          DataCell(Text(currencyFormat.format(bill.totalTax), style: const TextStyle(fontSize: 12))),
                          DataCell(Text(currencyFormat.format(bill.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          DataCell(
                            QtBadge(
                              label: bill.paymentStatus,
                              color: bill.paymentStatus == 'Paid' ? QtColors.darkSuccess : QtColors.darkError,
                            ),
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 18),
                              tooltip: 'Preview PDF',
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
    );
  }

  void _showAddEditPartyDialog(BuildContext context, {Party? party}) {
    final isEditing = party != null;
    final formKey = GlobalKey<FormState>();

    final nameCtrl = TextEditingController(text: party?.name ?? '');
    final mobileCtrl = TextEditingController(text: party?.mobile ?? '');
    final addressCtrl = TextEditingController(text: party?.address ?? '');
    final gstinCtrl = TextEditingController(text: party?.gstin ?? '');
    final emailCtrl = TextEditingController(text: party?.email ?? '');
    String selectedState = party?.state ?? 'Maharashtra';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: isDark ? QtColors.darkSurface : QtColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: isDark ? QtColors.darkBorder : QtColors.lightBorder),
              ),
              child: SizedBox(
                width: 550,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QtPanelHeader(
                      title: isEditing ? 'Edit Customer' : 'Add New Customer',
                      icon: isEditing ? Icons.edit : Icons.person_add,
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextFormField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(labelText: 'Customer / Firm Name *'),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: mobileCtrl,
                                      decoration: const InputDecoration(labelText: 'Mobile Number *'),
                                      keyboardType: TextInputType.phone,
                                      validator: (val) => val == null || val.trim().length < 10 ? 'Valid 10-digit mobile required' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: selectedState,
                                      decoration: const InputDecoration(labelText: 'State *'),
                                      items: indianStates.map((st) {
                                        return DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 13)));
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setDialogState(() => selectedState = val);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: addressCtrl,
                                decoration: const InputDecoration(labelText: 'Full Address *'),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Address is required' : null,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: gstinCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'GSTIN (Optional)',
                                        hintText: 'e.g. 27AAAAA0000A1Z5',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextFormField(
                                      controller: emailCtrl,
                                      decoration: const InputDecoration(labelText: 'Email Address (Optional)'),
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  QtButton(
                                    label: 'Cancel',
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  const SizedBox(width: 10),
                                  QtButton(
                                    label: isEditing ? 'Save Changes' : 'Create Customer',
                                    icon: Icons.check,
                                    isPrimary: true,
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        final newParty = Party(
                                          id: isEditing ? party.id : DateTime.now().millisecondsSinceEpoch.toString(),
                                          name: nameCtrl.text.trim(),
                                          mobile: mobileCtrl.text.trim(),
                                          address: addressCtrl.text.trim(),
                                          state: selectedState,
                                          gstin: gstinCtrl.text.trim().isNotEmpty ? gstinCtrl.text.trim().toUpperCase() : null,
                                          email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                                        );

                                        if (isEditing) {
                                          ref.read(partiesProvider.notifier).updateParty(newParty);
                                        } else {
                                          ref.read(partiesProvider.notifier).addParty(newParty);
                                        }

                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Customer ${newParty.name} saved successfully.')),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteParty(BuildContext context, Party party) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Customer ${party.name}?'),
          content: const Text('Are you sure you want to remove this customer record?'),
          actions: [
            QtButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
            QtButton(
              label: 'Delete',
              isDanger: true,
              onPressed: () {
                ref.read(partiesProvider.notifier).deleteParty(party.id);
                if (_selectedPartyForHistory?.id == party.id) {
                  setState(() => _selectedPartyForHistory = null);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
