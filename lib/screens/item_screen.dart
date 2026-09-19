import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/item.dart';
import '../providers/app_providers.dart';
import '../services/ai_assistant_service.dart';
import '../services/csv_exporter.dart';
import '../theme/qt_theme.dart';
import '../widgets/qt_widgets.dart';

const List<double> gstSlabs = [0.0, 5.0, 12.0, 18.0, 28.0];

class ItemScreen extends ConsumerStatefulWidget {
  const ItemScreen({super.key});

  @override
  ConsumerState<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends ConsumerState<ItemScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(itemsProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    final filteredItems = items.where((i) {
      final q = _searchQuery.toLowerCase();
      return i.name.toLowerCase().contains(q) ||
          (i.hsnCode?.toLowerCase().contains(q) ?? false) ||
          i.gstPercent.toString().contains(q);
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
                      hintText: 'Search catalog items by name, HSN code, or GST %...',
                      prefixIcon: Icon(Icons.search, size: 18),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                QtButton(
                  label: 'Add Product Item',
                  icon: Icons.add_box,
                  isPrimary: true,
                  onPressed: () => _showAddEditItemDialog(context),
                ),
                const SizedBox(width: 8),
                QtButton(
                  label: 'Export Catalog CSV',
                  icon: Icons.download,
                  onPressed: () {
                    final csv = CsvExporter.exportItemsToCsv(items);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Exported ${items.length} product items to CSV.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Catalog Table Panel
          QtCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                QtPanelHeader(
                  title: 'Product Catalog (${filteredItems.length} items)',
                  icon: Icons.inventory,
                ),
                filteredItems.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No catalog items found.'),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowHeight: 40,
                          dataRowMinHeight: 46,
                          dataRowMaxHeight: 46,
                          columns: const [
                            DataColumn(label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('HSN/SAC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Unit Price (Excl. Tax)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('GST Slab', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Tax Amt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Price (Incl. Tax)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          ],
                          rows: filteredItems.map((item) {
                            final taxAmt = item.unitPrice * (item.gstPercent / 100.0);
                            final totalPrice = item.unitPrice + taxAmt;

                            return DataRow(
                              cells: [
                                DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataCell(Text(item.hsnCode ?? '-', style: const TextStyle(fontSize: 12))),
                                DataCell(Text(currencyFormat.format(item.unitPrice), style: const TextStyle(fontSize: 12))),
                                DataCell(
                                  QtBadge(
                                    label: '${item.gstPercent.toStringAsFixed(0)}% GST',
                                    color: QtColors.darkPrimary,
                                  ),
                                ),
                                DataCell(Text(currencyFormat.format(taxAmt), style: const TextStyle(fontSize: 12, color: Colors.grey))),
                                DataCell(Text(currencyFormat.format(totalPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: Colors.amber),
                                        tooltip: 'Edit Item',
                                        onPressed: () => _showAddEditItemDialog(context, item: item),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: QtColors.darkError),
                                        tooltip: 'Delete Item',
                                        onPressed: () => _confirmDeleteItem(context, item),
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
        ],
      ),
    );
  }

  void _showAddEditItemDialog(BuildContext context, {Item? item}) {
    final isEditing = item != null;
    final formKey = GlobalKey<FormState>();

    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final hsnCtrl = TextEditingController(text: item?.hsnCode ?? '');
    final priceCtrl = TextEditingController(text: item != null ? item.unitPrice.toString() : '');
    double selectedGst = item?.gstPercent ?? 18.0;
    bool isAiLoading = false;

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
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QtPanelHeader(
                      title: isEditing ? 'Edit Catalog Item' : 'Add New Catalog Item',
                      icon: isEditing ? Icons.edit : Icons.add_box,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(labelText: 'Item / Product Name *'),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Product name is required' : null,
                              ),
                              const SizedBox(height: 8),

                              // Gemini AI Suggestion Action Button
                              Align(
                                alignment: Alignment.centerRight,
                                child: InkWell(
                                  onTap: isAiLoading
                                      ? null
                                      : () async {
                                          final itemName = nameCtrl.text.trim();
                                          if (itemName.isEmpty) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Please enter an item name first.')),
                                            );
                                            return;
                                          }
                                          setDialogState(() => isAiLoading = true);
                                          final apiKey = ref.read(geminiApiKeyProvider);
                                          final sugg = await AiAssistantService.suggestHsnAndGstRate(
                                            itemName: itemName,
                                            apiKey: apiKey,
                                          );
                                          setDialogState(() {
                                            hsnCtrl.text = sugg.hsnCode;
                                            selectedGst = sugg.gstPercent;
                                            isAiLoading = false;
                                          });
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('✨ Gemini AI suggested HSN ${sugg.hsnCode} & ${sugg.gstPercent.toStringAsFixed(0)}% GST (${sugg.category})')),
                                          );
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: QtColors.darkAccent.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(color: QtColors.darkAccent),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        isAiLoading
                                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                                            : const Icon(Icons.auto_awesome, size: 13, color: QtColors.darkPrimary),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '✨ Ask Gemini AI for HSN & GST Slab',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: QtColors.darkPrimary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: hsnCtrl,
                                      decoration: const InputDecoration(labelText: 'HSN / SAC Code'),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextFormField(
                                      controller: priceCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Unit Price (Excl. Tax) *',
                                        prefixText: '₹ ',
                                      ),
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) return 'Price required';
                                        if (double.tryParse(val.trim()) == null) return 'Invalid price';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<double>(
                                value: selectedGst,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'GST Tax Slab *'),
                                items: gstSlabs.map((slab) {
                                  return DropdownMenuItem(
                                    value: slab,
                                    child: Text('${slab.toStringAsFixed(0)}% GST Slab', style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => selectedGst = val);
                                },
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
                                    label: isEditing ? 'Save Changes' : 'Add to Catalog',
                                    icon: Icons.check,
                                    isPrimary: true,
                                    onPressed: () {
                                      if (formKey.currentState!.validate()) {
                                        final newItem = Item(
                                          id: isEditing ? item.id : DateTime.now().millisecondsSinceEpoch.toString(),
                                          name: nameCtrl.text.trim(),
                                          hsnCode: hsnCtrl.text.trim().isNotEmpty ? hsnCtrl.text.trim() : null,
                                          unitPrice: double.parse(priceCtrl.text.trim()),
                                          gstPercent: selectedGst,
                                        );

                                        if (isEditing) {
                                          ref.read(itemsProvider.notifier).updateItem(newItem);
                                        } else {
                                          ref.read(itemsProvider.notifier).addItem(newItem);
                                        }

                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Item ${newItem.name} saved successfully.')),
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

  void _confirmDeleteItem(BuildContext context, Item item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete ${item.name}?'),
          content: const Text('Are you sure you want to remove this product from the catalog?'),
          actions: [
            QtButton(label: 'Cancel', onPressed: () => Navigator.of(context).pop()),
            QtButton(
              label: 'Delete',
              isDanger: true,
              onPressed: () {
                ref.read(itemsProvider.notifier).deleteItem(item.id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
