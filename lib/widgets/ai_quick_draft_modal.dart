import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/ai_assistant_service.dart';
import '../theme/qt_theme.dart';
import '../widgets/qt_widgets.dart';

class AiQuickDraftModal extends ConsumerStatefulWidget {
  const AiQuickDraftModal({super.key});

  static Future<AiDraftResult?> show(BuildContext context) {
    return showDialog<AiDraftResult>(
      context: context,
      builder: (context) => const AiQuickDraftModal(),
    );
  }

  @override
  ConsumerState<AiQuickDraftModal> createState() => _AiQuickDraftModalState();
}

class _AiQuickDraftModalState extends ConsumerState<AiQuickDraftModal> {
  final TextEditingController _promptCtrl = TextEditingController(
    text: 'Create bill for Manish Shah with 2 Office Chair and 3 USB-C Cable',
  );
  bool _isLoading = false;

  final List<String> _examples = [
    '2 Wireless Mouse and 1 External Hard Disk for Sneha Iyer',
    '3 Office Chair and 5 Steel Water Bottle for Karan Patel',
    '4 Printer Paper A4 and 2 Laptop Bag for Manish Shah',
  ];

  void _draftWithAi() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    final parties = ref.read(partiesProvider);
    final items = ref.read(itemsProvider);
    final shop = ref.read(shopProfileProvider);
    final apiKey = ref.read(geminiApiKeyProvider);

    final draftResult = await AiAssistantService.parseNaturalLanguageBill(
      prompt: prompt,
      parties: parties,
      items: items,
      shopState: shop.state,
      apiKey: apiKey,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop(draftResult);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? QtColors.darkSurface : QtColors.lightSurface;
    final borderColor = isDark ? QtColors.darkBorder : QtColors.lightBorder;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Qt Panel Header
            QtPanelHeader(
              title: '✨ Gemini AI Natural-Language Invoice Drafter',
              icon: Icons.auto_awesome,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Type or speak a plain sentence to auto-draft an invoice. Gemini AI will match the customer and catalog items automatically:',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),

                  // Prompt Text Area
                  TextField(
                    controller: _promptCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Natural Language Invoicing Prompt *',
                      hintText: 'e.g. 2 Wireless Mouse and 1 Office Chair for Manish Shah',
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Example Prompt Chips
                  const Text('TRY EXAMPLE PROMPTS:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _examples.map((ex) {
                      return InkWell(
                        onTap: () => setState(() => _promptCtrl.text = ex),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: QtColors.darkAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(color: QtColors.darkAccent.withOpacity(0.3)),
                          ),
                          child: Text(ex, style: const TextStyle(fontSize: 11, color: QtColors.darkPrimary)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      QtButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : QtButton(
                              label: 'DRAFT INVOICE WITH AI',
                              icon: Icons.auto_awesome,
                              isPrimary: true,
                              onPressed: _draftWithAi,
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
