import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop_profile.dart';
import '../providers/app_providers.dart';
import '../theme/qt_theme.dart';
import '../widgets/qt_widgets.dart';
import 'party_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameCtrl;
  late TextEditingController gstinCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController bankCtrl;
  late TextEditingController accCtrl;
  late TextEditingController ifscCtrl;
  late TextEditingController termsCtrl;
  late TextEditingController apiKeyCtrl;
  late String selectedState;

  @override
  void initState() {
    super.initState();
    final shop = ref.read(shopProfileProvider);
    final apiKey = ref.read(geminiApiKeyProvider);
    nameCtrl = TextEditingController(text: shop.name);
    gstinCtrl = TextEditingController(text: shop.gstin);
    addressCtrl = TextEditingController(text: shop.address);
    phoneCtrl = TextEditingController(text: shop.phone);
    emailCtrl = TextEditingController(text: shop.email);
    bankCtrl = TextEditingController(text: shop.bankName);
    accCtrl = TextEditingController(text: shop.accountNo);
    ifscCtrl = TextEditingController(text: shop.ifscCode);
    termsCtrl = TextEditingController(text: shop.terms);
    apiKeyCtrl = TextEditingController(text: apiKey);
    selectedState = shop.state;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = ref.watch(qtThemeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme & Appearance Box
          QtCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const QtPanelHeader(
                  title: 'Visual Theme & Workbench Options',
                  icon: Icons.palette,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qt Workbench Theme Style',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isDark ? QtColors.darkTextPrimary : QtColors.lightTextPrimary,
                            ),
                          ),
                          const Text(
                            'Switch between Qt Creator Slate Dark Mode and Qt Fusion Light Mode',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Light', style: TextStyle(fontSize: 12)),
                          Switch(
                            value: isDarkTheme,
                            activeColor: QtColors.darkPrimary,
                            onChanged: (val) {
                              ref.read(qtThemeModeProvider.notifier).state = val;
                            },
                          ),
                          const Text('Qt Dark', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gemini AI Configuration Card
          QtCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const QtPanelHeader(
                  title: '✨ Google Gemini AI Configuration',
                  icon: Icons.auto_awesome,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Google Gemini API Key (Optional)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enter your Gemini API Key from Google AI Studio. If left empty, the built-in smart AI engine processes all prompts, HSN classifications, and chat queries automatically!',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: apiKeyCtrl,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Gemini API Key (AIzaSy...)',
                                prefixIcon: Icon(Icons.key, size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          QtButton(
                            label: 'Save Key',
                            icon: Icons.check,
                            isPrimary: true,
                            onPressed: () {
                              ref.read(geminiApiKeyProvider.notifier).setApiKey(apiKeyCtrl.text.trim());
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gemini API key saved!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Shop & GST Configuration Form
          QtCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                const QtPanelHeader(
                  title: 'Shop & Business Tax Profile',
                  icon: Icons.store,
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: nameCtrl,
                                decoration: const InputDecoration(labelText: 'Shop / Business Name *'),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Shop name required' : null,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: gstinCtrl,
                                decoration: const InputDecoration(labelText: 'Shop GSTIN *'),
                                validator: (val) => val == null || val.trim().isEmpty ? 'GSTIN required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedState,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Shop State (Place of Supply Base) *'),
                                items: indianStates.map((st) {
                                  return DropdownMenuItem(value: st, child: Text(st, style: const TextStyle(fontSize: 13)));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => selectedState = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: phoneCtrl,
                                decoration: const InputDecoration(labelText: 'Contact Phone Number *'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: addressCtrl,
                                decoration: const InputDecoration(labelText: 'Shop Address *'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: emailCtrl,
                                decoration: const InputDecoration(labelText: 'Email Address *'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'BANK DETAILS FOR INVOICE PDF',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5, color: QtColors.darkPrimary),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: bankCtrl,
                                decoration: const InputDecoration(labelText: 'Bank Name'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: accCtrl,
                                decoration: const InputDecoration(labelText: 'Account Number'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: ifscCtrl,
                                decoration: const InputDecoration(labelText: 'IFSC Code'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: termsCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(labelText: 'Terms & Conditions on Invoices'),
                        ),
                        const SizedBox(height: 24),

                        Align(
                          alignment: Alignment.centerRight,
                          child: QtButton(
                            label: 'Save Profile Settings',
                            icon: Icons.save,
                            isPrimary: true,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                final updated = ShopProfile(
                                  name: nameCtrl.text.trim(),
                                  gstin: gstinCtrl.text.trim().toUpperCase(),
                                  state: selectedState,
                                  address: addressCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  email: emailCtrl.text.trim(),
                                  bankName: bankCtrl.text.trim(),
                                  accountNo: accCtrl.text.trim(),
                                  ifscCode: ifscCtrl.text.trim(),
                                  terms: termsCtrl.text.trim(),
                                );

                                ref.read(shopProfileProvider.notifier).updateProfile(updated);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Shop profile updated successfully!')),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
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
