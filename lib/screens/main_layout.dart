import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../providers/sample_data.dart';
import '../theme/qt_theme.dart';
import '../widgets/qt_widgets.dart';
import '../widgets/ai_quick_draft_modal.dart';
import 'dashboard_screen.dart';
import 'bill_create_screen.dart';
import 'bill_history_screen.dart';
import 'party_screen.dart';
import 'item_screen.dart';
import 'settings_screen.dart';
import 'ai_chat_screen.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(activeTabProvider);
    final isDarkTheme = ref.watch(qtThemeModeProvider);
    final shop = ref.watch(shopProfileProvider);
    final bills = ref.watch(billsProvider);
    final auth = ref.watch(authProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? QtColors.darkHeader : QtColors.lightHeader;
    final borderCol = isDark ? QtColors.darkBorder : QtColors.lightBorder;

    final List<Widget> screens = const [
      DashboardScreen(),
      BillCreateScreen(),
      BillHistoryScreen(),
      PartyScreen(),
      ItemScreen(),
      AiChatScreen(),
      SettingsScreen(),
    ];

    final List<Map<String, dynamic>> tabs = [
      {'title': 'Dashboard', 'icon': Icons.space_dashboard},
      {'title': 'Create Bill', 'icon': Icons.add_shopping_cart},
      {'title': 'Bill History', 'icon': Icons.history},
      {'title': 'Customers', 'icon': Icons.people},
      {'title': 'Catalog Items', 'icon': Icons.inventory_2},
      {'title': '✨ Gemini AI Analyst', 'icon': Icons.auto_awesome},
      {'title': 'Settings', 'icon': Icons.settings},
    ];

    return Scaffold(
      body: Column(
        children: [
          // Qt Desktop Top Menu Bar
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(bottom: BorderSide(color: borderCol, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Qt Window Control Dots
                  Row(
                    children: [
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFF5F56), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFFFFBD2E), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF27C93F), shape: BoxShape.circle)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  const SizedBox(
                    height: 16,
                    child: VerticalDivider(width: 1, indent: 2, endIndent: 2),
                  ),
                  const SizedBox(width: 12),

                  // Top Menu Items
                  _buildMenuItem(context, 'File', [
                    PopupMenuItem(
                      value: 'new',
                      child: const Row(children: [Icon(Icons.add, size: 16), SizedBox(width: 8), Text('New GST Bill')]),
                      onTap: () => ref.read(activeTabProvider.notifier).state = 1,
                    ),
                    PopupMenuItem(
                      value: 'reload_csv',
                      child: const Row(children: [Icon(Icons.refresh, size: 16), SizedBox(width: 8), Text('Reload Fake CSV Dataset')]),
                      onTap: () {
                        ref.read(partiesProvider.notifier).reloadFromList(SampleData.initialParties);
                        ref.read(itemsProvider.notifier).reloadFromList(SampleData.initialItems);
                        ref.read(billsProvider.notifier).reloadFromList(SampleData.getInitialBills());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Successfully reloaded fake data from CSV assets (15 customers, 18 items, 20 bills).')),
                        );
                      },
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: const Row(children: [Icon(Icons.logout, size: 16, color: QtColors.darkError), SizedBox(width: 8), Text('Sign Out', style: TextStyle(color: QtColors.darkError))]),
                      onTap: () => ref.read(authProvider.notifier).logout(),
                    ),
                  ]),
                  _buildMenuItem(context, 'Master Data', [
                    PopupMenuItem(
                      value: 'parties',
                      child: const Row(children: [Icon(Icons.people, size: 16), SizedBox(width: 8), Text('Customers Directory')]),
                      onTap: () => ref.read(activeTabProvider.notifier).state = 3,
                    ),
                    PopupMenuItem(
                      value: 'items',
                      child: const Row(children: [Icon(Icons.inventory, size: 16), SizedBox(width: 8), Text('Product Catalog')]),
                      onTap: () => ref.read(activeTabProvider.notifier).state = 4,
                    ),
                  ]),
                  _buildMenuItem(context, '✨ Gemini AI', [
                    PopupMenuItem(
                      value: 'ai_draft',
                      child: const Row(children: [Icon(Icons.auto_awesome, size: 16, color: QtColors.darkPrimary), SizedBox(width: 8), Text('Natural Language Bill Draft')]),
                      onTap: () async {
                        final res = await AiQuickDraftModal.show(context);
                        if (res != null) {
                          ref.read(activeTabProvider.notifier).state = 1;
                        }
                      },
                    ),
                    PopupMenuItem(
                      value: 'ai_chat',
                      child: const Row(children: [Icon(Icons.psychology, size: 16, color: QtColors.darkAccent), SizedBox(width: 8), Text('GST Chat Analyst')]),
                      onTap: () => ref.read(activeTabProvider.notifier).state = 5,
                    ),
                  ]),
                  _buildMenuItem(context, 'View', [
                    PopupMenuItem(
                      value: 'theme',
                      child: Row(children: [
                        Icon(isDarkTheme ? Icons.light_mode : Icons.dark_mode, size: 16),
                        const SizedBox(width: 8),
                        Text(isDarkTheme ? 'Light Mode' : 'Qt Dark Mode'),
                      ]),
                      onTap: () => ref.read(qtThemeModeProvider.notifier).state = !isDarkTheme,
                    ),
                  ]),
                  _buildMenuItem(context, 'Help', [
                    PopupMenuItem(
                      value: 'about',
                      child: const Row(children: [Icon(Icons.info_outline, size: 16), SizedBox(width: 8), Text('About GST Workbench')]),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Qt GST Billing Workbench',
                          applicationVersion: 'v2.4.0 (Authenticated Admin Portal)',
                          applicationLegalese: '© 2026 Apex Billing Systems. GST Compliant.',
                        );
                      },
                    ),
                  ]),

                  const SizedBox(width: 24),

                  // Company & Logged-in User Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isDark ? QtColors.darkAccent : QtColors.lightAccent).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: (isDark ? QtColors.darkAccent : QtColors.lightAccent).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.business, size: 14, color: isDark ? QtColors.darkPrimary : QtColors.lightAccent),
                        const SizedBox(width: 6),
                        Text(
                          '${auth.companyName} (${auth.username})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? QtColors.darkTextPrimary : QtColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => ref.read(authProvider.notifier).logout(),
                          child: const Icon(Icons.power_settings_new, size: 14, color: QtColors.darkError),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Workbench Area: Left Sidebar Nav Rail + Active Content Screen
          Expanded(
            child: Row(
              children: [
                // Left Qt Side Navigation Rail
                Container(
                  width: 180,
                  decoration: BoxDecoration(
                    color: headerBg,
                    border: Border(right: BorderSide(color: borderCol, width: 1)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: tabs.length,
                          itemBuilder: (context, index) {
                            final isSelected = activeTab == index;
                            final tab = tabs[index];

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: InkWell(
                                onTap: () => ref.read(activeTabProvider.notifier).state = index,
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (isDark ? QtColors.darkAccent : QtColors.lightAccent).withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    border: isSelected
                                        ? Border.all(color: isDark ? QtColors.darkAccent : QtColors.lightAccent, width: 1)
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        tab['icon'] as IconData,
                                        size: 16,
                                        color: isSelected
                                            ? (isDark ? QtColors.darkPrimary : QtColors.lightAccent)
                                            : (isDark ? QtColors.darkTextSecondary : QtColors.lightTextSecondary),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          tab['title'] as String,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected
                                                ? (isDark ? QtColors.darkTextPrimary : QtColors.lightTextPrimary)
                                                : (isDark ? QtColors.darkTextSecondary : QtColors.lightTextSecondary),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Main Screen Content
                Expanded(
                  child: Column(
                    children: [
                      // Qt Top Tab Indicator Bar
                      Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: headerBg,
                          border: Border(bottom: BorderSide(color: borderCol, width: 1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                border: Border(
                                  top: BorderSide(color: isDark ? QtColors.darkPrimary : QtColors.lightAccent, width: 2),
                                  right: BorderSide(color: borderCol, width: 1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    tabs[activeTab]['icon'] as IconData,
                                    size: 14,
                                    color: isDark ? QtColors.darkPrimary : QtColors.lightAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    tabs[activeTab]['title'] as String,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Screen View Container
                      Expanded(
                        child: IndexedStack(
                          index: activeTab,
                          children: screens,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Qt Bottom Status Bar
          Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: headerBg,
              border: Border(top: BorderSide(color: borderCol, width: 1)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: QtColors.darkSuccess),
                  const SizedBox(width: 6),
                  Text(
                    'GST Tax Engine Active',
                    style: TextStyle(fontSize: 11, color: isDark ? QtColors.darkTextSecondary : QtColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 16),
                  const SizedBox(height: 14, child: VerticalDivider(width: 1)),
                  const SizedBox(width: 16),
                  Text(
                    'User: ${auth.username}',
                    style: TextStyle(fontSize: 11, color: isDark ? QtColors.darkTextSecondary : QtColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 16),
                  const SizedBox(height: 14, child: VerticalDivider(width: 1)),
                  const SizedBox(width: 16),
                  Text(
                    'Place of Supply: ${shop.state}',
                    style: TextStyle(fontSize: 11, color: isDark ? QtColors.darkTextSecondary : QtColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 16),
                  const SizedBox(height: 14, child: VerticalDivider(width: 1)),
                  const SizedBox(width: 16),
                  Text(
                    'Total Invoices: ${bills.length}',
                    style: TextStyle(fontSize: 11, color: isDark ? QtColors.darkTextSecondary : QtColors.lightTextSecondary),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    DateFormat('dd-MMM-yyyy | HH:mm').format(DateTime.now()),
                    style: TextStyle(fontSize: 11, color: isDark ? QtColors.darkTextSecondary : QtColors.lightTextSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, String label, List<PopupMenuEntry<String>> items) {
    return PopupMenuButton<String>(
      tooltip: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      itemBuilder: (context) => items,
    );
  }
}
