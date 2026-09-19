import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../services/ai_assistant_service.dart';
import '../theme/qt_theme.dart';
import '../widgets/qt_widgets.dart';
import '../widgets/pdf_preview_dialog.dart';
import '../widgets/ai_quick_draft_modal.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider);
    final parties = ref.watch(partiesProvider);
    final items = ref.watch(itemsProvider);
    final shop = ref.watch(shopProfileProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    // Calculate aggregated metrics
    double totalSales = 0;
    double totalTax = 0;
    double totalCgst = 0;
    double totalSgst = 0;
    double totalIgst = 0;

    for (final bill in bills) {
      totalSales += bill.grandTotal;
      totalTax += bill.totalTax;
      totalCgst += bill.totalCgst;
      totalSgst += bill.totalSgst;
      totalIgst += bill.totalIgst;
    }

    // AI Forecast Suggestions
    final restockSuggestions = AiAssistantService.forecastInventoryDemand(bills: bills, items: items);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final double cardWidth = constraints.maxWidth > 900
                  ? (constraints.maxWidth - 48) / 4
                  : constraints.maxWidth > 600
                      ? (constraints.maxWidth - 16) / 2
                      : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: QtStatCard(
                      title: 'Total Revenue',
                      value: currencyFormat.format(totalSales),
                      subtitle: 'Across ${bills.length} invoices',
                      icon: Icons.account_balance_wallet,
                      accentColor: QtColors.darkPrimary,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: QtStatCard(
                      title: 'Total GST Collected',
                      value: currencyFormat.format(totalTax),
                      subtitle: 'CGST+SGST: ${currencyFormat.format(totalCgst + totalSgst)} | IGST: ${currencyFormat.format(totalIgst)}',
                      icon: Icons.receipt_long,
                      accentColor: QtColors.darkSuccess,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: QtStatCard(
                      title: 'Registered Customers',
                      value: '${parties.length}',
                      subtitle: 'Active party accounts',
                      icon: Icons.people_alt,
                      accentColor: QtColors.darkWarning,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: QtStatCard(
                      title: 'Product Catalog',
                      value: '${items.length}',
                      subtitle: 'Reusable catalog items',
                      icon: Icons.inventory_2,
                      accentColor: QtColors.darkAccent,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Quick Action Banner with AI Prompting
          QtCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on, color: QtColors.darkWarning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'QUICK ACTIONS:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? QtColors.darkTextPrimary : QtColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                QtButton(
                  label: '✨ AI Natural Draft',
                  icon: Icons.auto_awesome,
                  isPrimary: true,
                  onPressed: () async {
                    final res = await AiQuickDraftModal.show(context);
                    if (res != null) {
                      ref.read(activeTabProvider.notifier).state = 1;
                    }
                  },
                ),
                QtButton(
                  label: 'Create GST Bill',
                  icon: Icons.add_shopping_cart,
                  onPressed: () => ref.read(activeTabProvider.notifier).state = 1,
                ),
                QtButton(
                  label: 'Add Customer',
                  icon: Icons.person_add,
                  onPressed: () => ref.read(activeTabProvider.notifier).state = 3,
                ),
                QtButton(
                  label: 'Ask Gemini AI Analyst',
                  icon: Icons.psychology,
                  onPressed: () => ref.read(activeTabProvider.notifier).state = 6, // AI Assistant tab
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recent Invoices Table & Tax Breakdown Sidebar
          LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 900;

              final Widget tableWidget = QtCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    QtPanelHeader(
                      title: 'Recent Invoices (Latest 5)',
                      icon: Icons.history,
                      actions: [
                        QtButton(
                          label: 'View All',
                          icon: Icons.arrow_forward,
                          onPressed: () => ref.read(activeTabProvider.notifier).state = 2,
                        ),
                      ],
                    ),
                    bills.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text('No bills created yet.'),
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
                                DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('State', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                DataColumn(label: Text('PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                              ],
                              rows: bills.take(5).map((bill) {
                                final isIntra = bill.totalIgst == 0;
                                return DataRow(
                                  cells: [
                                    DataCell(Text(bill.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                    DataCell(Text(DateFormat('dd-MMM-yyyy').format(bill.date), style: const TextStyle(fontSize: 12))),
                                    DataCell(Text(bill.partyName, style: const TextStyle(fontSize: 12))),
                                    DataCell(
                                      QtBadge(
                                        label: bill.partyState,
                                        color: isIntra ? QtColors.darkPrimary : QtColors.darkWarning,
                                      ),
                                    ),
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
                                        tooltip: 'View / Print PDF Invoice',
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

              final Widget summaryWidget = Column(
                children: [
                  QtCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        const QtPanelHeader(
                          title: 'GST Tax Summary',
                          icon: Icons.pie_chart,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildTaxSummaryRow(context, 'Total Taxable Sales:', currencyFormat.format(bills.fold(0.0, (sum, b) => sum + b.subtotal))),
                              const Divider(height: 16),
                              _buildTaxSummaryRow(context, 'CGST Collected (Intra):', currencyFormat.format(totalCgst), color: QtColors.darkPrimary),
                              _buildTaxSummaryRow(context, 'SGST Collected (Intra):', currencyFormat.format(totalSgst), color: QtColors.darkPrimary),
                              _buildTaxSummaryRow(context, 'IGST Collected (Inter):', currencyFormat.format(totalIgst), color: QtColors.darkWarning),
                              const Divider(height: 16),
                              _buildTaxSummaryRow(
                                context,
                                'Total Tax Liability:',
                                currencyFormat.format(totalTax),
                                isBold: true,
                                color: QtColors.darkSuccess,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI Demand & Inventory Forecast Card
                  QtCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        const QtPanelHeader(
                          title: '✨ AI Demand & Restock Forecast',
                          icon: Icons.trending_up,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: restockSuggestions.take(4).map((sugg) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(sugg.item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), overflow: TextOverflow.ellipsis),
                                          Text('Sold: ${sugg.totalSold} pcs | Projected: ~${sugg.projectedWeeklyDemand}/wk', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    QtBadge(
                                      label: sugg.urgency == 'High' ? 'Fast Mover' : 'Steady Demand',
                                      color: sugg.urgency == 'High' ? QtColors.darkSuccess : QtColors.darkPrimary,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: tableWidget),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: summaryWidget),
                  ],
                );
              }

              return Column(
                children: [
                  tableWidget,
                  const SizedBox(height: 16),
                  summaryWidget,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaxSummaryRow(BuildContext context, String label, String value, {bool isBold = false, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isDark ? QtColors.darkTextSecondary : QtColors.lightTextSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? (isDark ? QtColors.darkTextPrimary : QtColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
