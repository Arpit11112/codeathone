import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/ai_assistant_service.dart';
import '../theme/qt_theme.dart';
import '../widgets/qt_widgets.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final TextEditingController _queryCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: '👋 Hello! I am your Gemini GST AI Analyst.\n'
          'Ask me anything about your 20 invoices, GST tax breakdown (CGST/SGST vs IGST), customer balances, or sales metrics.',
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  bool _isLoading = false;

  final List<String> _suggestedPrompts = [
    'Is payment complete for Sneha Iyer?',
    'Check payment status of Raj Patel',
    'Is payment complete or not for all invoices?',
    'What is my total GST tax collected?',
    'Show top customer by sales revenue',
  ];

  void _sendMessage(String query) async {
    if (query.trim().isEmpty || _isLoading) return;

    final userMsg = query.trim();
    _queryCtrl.clear();

    setState(() {
      _messages.add(ChatMessage(text: userMsg, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });

    _scrollToBottom();

    final bills = ref.read(billsProvider);
    final parties = ref.read(partiesProvider);
    final items = ref.read(itemsProvider);
    final shop = ref.read(shopProfileProvider);
    final apiKey = ref.read(geminiApiKeyProvider);

    final aiResponse = await AiAssistantService.askGstChatAssistant(
      query: userMsg,
      bills: bills,
      parties: parties,
      items: items,
      shop: shop,
      apiKey: apiKey,
    );

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: aiResponse, isUser: false, timestamp: DateTime.now()));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header Card
          QtCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: QtColors.darkPrimary, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✨ GEMINI GST AI ANALYST & ASSISTANT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.8,
                        color: isDark ? QtColors.darkTextPrimary : QtColors.lightTextPrimary,
                      ),
                    ),
                    const Text(
                      'Ask questions in natural language to query tax liability, top customers, and sales trends',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const Spacer(),
                QtBadge(
                  label: 'Gemini AI Ready',
                  color: QtColors.darkSuccess,
                  icon: Icons.auto_awesome,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Suggested Prompts Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestedPrompts.map((prompt) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.tips_and_updates, size: 14, color: QtColors.darkWarning),
                    label: Text(prompt, style: const TextStyle(fontSize: 11)),
                    onPressed: () => _sendMessage(prompt),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Chat Messages List Container
          Expanded(
            child: QtCard(
              padding: const EdgeInsets.all(12),
              child: ListView.builder(
                controller: _scrollCtrl,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(context, msg);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Input Control Bar
          QtCard(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ask Gemini AI: e.g. "What was my total CGST and SGST tax?"...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : QtButton(
                        label: 'ASK GEMINI',
                        icon: Icons.send,
                        isPrimary: true,
                        onPressed: () => _sendMessage(_queryCtrl.text),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: QtColors.darkAccent.withOpacity(0.2),
              child: const Icon(Icons.auto_awesome, size: 14, color: QtColors.darkPrimary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: msg.isUser
                    ? (isDark ? QtColors.darkAccent : QtColors.lightAccent)
                    : (isDark ? QtColors.darkHeader : QtColors.lightHeader),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: msg.isUser
                      ? (isDark ? QtColors.darkAccent : QtColors.lightAccent)
                      : (isDark ? QtColors.darkBorder : QtColors.lightBorder),
                ),
              ),
              child: SelectableText(
                msg.text.replaceAll('**', '').replaceAll('`', ''),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: msg.isUser
                      ? Colors.white
                      : (isDark ? QtColors.darkTextPrimary : QtColors.lightTextPrimary),
                ),
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: QtColors.darkPrimary,
              child: Icon(Icons.person, size: 14, color: Colors.black),
            ),
          ],
        ],
      ),
    );
  }
}
