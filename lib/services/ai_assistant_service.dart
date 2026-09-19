import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/party.dart';
import '../models/item.dart';
import '../models/bill.dart';
import '../models/shop_profile.dart';
import 'gst_calculator.dart';

class AiDraftResult {
  final Party? party;
  final List<BillItem> lineItems;
  final String rawSummary;

  const AiDraftResult({
    this.party,
    required this.lineItems,
    required this.rawSummary,
  });
}

class HsnSuggestion {
  final String hsnCode;
  final double gstPercent;
  final String category;
  final String reasoning;

  const HsnSuggestion({
    required this.hsnCode,
    required this.gstPercent,
    required this.category,
    required this.reasoning,
  });
}

class BillAnomaly {
  final String title;
  final String description;
  final bool isWarning;

  const BillAnomaly({
    required this.title,
    required this.description,
    this.isWarning = true,
  });
}

class RestockSuggestion {
  final Item item;
  final int totalSold;
  final int projectedWeeklyDemand;
  final String urgency; // 'High', 'Medium', 'Normal'

  const RestockSuggestion({
    required this.item,
    required this.totalSold,
    required this.projectedWeeklyDemand,
    required this.urgency,
  });
}

class AiAssistantService {
  /// 1. Natural Language Bill Parser via Gemini API (with smart offline fallback)
  static Future<AiDraftResult> parseNaturalLanguageBill({
    required String prompt,
    required List<Party> parties,
    required List<Item> items,
    required String shopState,
    String? apiKey,
  }) async {
    // Attempt Gemini API call if key is available
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final partyNames = parties.map((p) => p.name).toList();
        final itemNames = items.map((i) => i.name).toList();

        final systemPrompt = '''
You are an AI assistant for a GST billing app.
Available Customers: ${jsonEncode(partyNames)}
Available Catalog Items: ${jsonEncode(itemNames)}

Parse the user's input: "$prompt"
Return ONLY a valid JSON object with format:
{
  "matchedParty": "customer name from list or null",
  "matchedItems": [
    {"itemName": "item name from list", "qty": 2}
  ]
}
''';

        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': systemPrompt}
                ]
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          if (text != null) {
            final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
            if (jsonMatch != null) {
              final parsed = jsonDecode(jsonMatch.group(0)!);
              return _buildDraftResultFromJson(parsed, parties, items, shopState);
            }
          }
        }
      } catch (_) {
        // Fallback to local smart parser on error
      }
    }

    // Local Smart Fuzzy Natural Language Parser
    return _parseNaturalLanguageLocal(prompt, parties, items, shopState);
  }

  static AiDraftResult _buildDraftResultFromJson(
    Map<String, dynamic> json,
    List<Party> parties,
    List<Item> items,
    String shopState,
  ) {
    Party? party;
    final partyName = json['matchedParty'] as String?;
    if (partyName != null) {
      party = parties.firstWhere(
        (p) => p.name.toLowerCase().contains(partyName.toLowerCase()),
        orElse: () => parties.first,
      );
    }

    final targetState = party?.state ?? shopState;
    final List<BillItem> lineItems = [];
    final rawItems = json['matchedItems'] as List? ?? [];

    for (final raw in rawItems) {
      final name = raw['itemName'] as String?;
      final qty = (raw['qty'] as num? ?? 1).toInt();
      if (name != null) {
        final catalogItem = items.firstWhere(
          (i) => i.name.toLowerCase().contains(name.toLowerCase()),
          orElse: () => items.first,
        );

        lineItems.add(GstCalculator.calculateLineItem(
          itemId: catalogItem.id,
          name: catalogItem.name,
          hsnCode: catalogItem.hsnCode,
          qty: qty,
          rate: catalogItem.unitPrice,
          gstPercent: catalogItem.gstPercent,
          partyState: targetState,
          shopState: shopState,
        ));
      }
    }

    return AiDraftResult(
      party: party,
      lineItems: lineItems,
      rawSummary: 'AI matched customer "${party?.name ?? 'Default'}" with ${lineItems.length} line items.',
    );
  }

  static AiDraftResult _parseNaturalLanguageLocal(
    String prompt,
    List<Party> parties,
    List<Item> items,
    String shopState,
  ) {
    final lower = prompt.toLowerCase();

    // 1. Match Party
    Party? matchedParty;
    for (final p in parties) {
      final firstName = p.name.split(' ').first.toLowerCase();
      if (lower.contains(p.name.toLowerCase()) || lower.contains(firstName)) {
        matchedParty = p;
        break;
      }
    }
    matchedParty ??= parties.isNotEmpty ? parties.first : null;

    final targetState = matchedParty?.state ?? shopState;
    final List<BillItem> lineItems = [];

    // 2. Match Items & Quantities
    for (final item in items) {
      final itemNameLower = item.name.toLowerCase();
      final words = itemNameLower.split(' ');
      bool matched = lower.contains(itemNameLower);

      if (!matched && words.length > 1) {
        matched = words.any((w) => w.length > 3 && lower.contains(w));
      }

      if (matched) {
        // Extract quantity preceding item name or numbers in prompt
        int qty = 1;
        final numRegex = RegExp(r'(\d+)\s*(?:pcs|pieces|x|nos)?\s*' + RegExp.escape(words.first));
        final match = numRegex.firstMatch(lower);

        if (match != null) {
          qty = int.tryParse(match.group(1)!) ?? 1;
        } else {
          // General digit match before item name
          final digitMatch = RegExp(r'(\d+)\s+([a-z]+)').firstMatch(lower);
          if (digitMatch != null) {
            qty = int.tryParse(digitMatch.group(1)!) ?? 1;
          }
        }

        lineItems.add(GstCalculator.calculateLineItem(
          itemId: item.id,
          name: item.name,
          hsnCode: item.hsnCode,
          qty: qty,
          rate: item.unitPrice,
          gstPercent: item.gstPercent,
          partyState: targetState,
          shopState: shopState,
        ));
      }
    }

    // Default first item if no items matched
    if (lineItems.isEmpty && items.isNotEmpty) {
      lineItems.add(GstCalculator.calculateLineItem(
        itemId: items.first.id,
        name: items.first.name,
        hsnCode: items.first.hsnCode,
        qty: 1,
        rate: items.first.unitPrice,
        gstPercent: items.first.gstPercent,
        partyState: targetState,
        shopState: shopState,
      ));
    }

    return AiDraftResult(
      party: matchedParty,
      lineItems: lineItems,
      rawSummary: 'AI extracted customer "${matchedParty?.name}" and ${lineItems.length} product items.',
    );
  }

  /// 2. GST Data Analyst Chat Assistant
  static Future<String> askGstChatAssistant({
    required String query,
    required List<Bill> bills,
    required List<Party> parties,
    required List<Item> items,
    required ShopProfile shop,
    String? apiKey,
  }) async {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2, locale: 'en_IN');

    // Aggregate summary statistics
    final double totalSales = bills.fold(0.0, (sum, b) => sum + b.grandTotal);
    final double totalTax = bills.fold(0.0, (sum, b) => sum + b.totalTax);
    final double totalCgst = bills.fold(0.0, (sum, b) => sum + b.totalCgst);
    final double totalSgst = bills.fold(0.0, (sum, b) => sum + b.totalSgst);
    final double totalIgst = bills.fold(0.0, (sum, b) => sum + b.totalIgst);

    final unpaidBills = bills.where((b) => b.paymentStatus == 'Unpaid' || b.paymentStatus == 'Partial').toList();

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final allInvoicesSummary = bills.map((b) =>
          '- ${b.invoiceNo} (Date: ${DateFormat('dd-MMM-yyyy').format(b.date)}): Customer="${b.partyName}", Amount=${currencyFormat.format(b.grandTotal)}, Status=${b.paymentStatus}'
        ).join('\n');

        final partySummaryList = parties.map((p) {
          final pBills = bills.where((b) => b.partyId == p.id || b.partyName.toLowerCase() == p.name.toLowerCase()).toList();
          final pTotal = pBills.fold(0.0, (sum, b) => sum + b.grandTotal);
          final pPaid = pBills.where((b) => b.paymentStatus == 'Paid').fold(0.0, (sum, b) => sum + b.grandTotal);
          final pUnpaid = pTotal - pPaid;
          final statusStr = pBills.isEmpty
              ? "No Invoices"
              : (pUnpaid <= 0 ? "Payment Complete (Paid)" : "Payment Incomplete (Pending: ${currencyFormat.format(pUnpaid)})");
          return '- Party "${p.name}" (${p.state}): Total Invoices=${pBills.length}, Total Billed=${currencyFormat.format(pTotal)}, Paid=${currencyFormat.format(pPaid)}, Pending=${currencyFormat.format(pUnpaid)}, Status=$statusStr';
        }).join('\n');

        final contextInfo = '''
Business Context:
Shop: ${shop.name} (State: ${shop.state}, GSTIN: ${shop.gstin})
Total Invoices Issued: ${bills.length}
Total Gross Revenue: ${currencyFormat.format(totalSales)}
Total Tax Liability: ${currencyFormat.format(totalTax)} (CGST: ${currencyFormat.format(totalCgst)}, SGST: ${currencyFormat.format(totalSgst)}, IGST: ${currencyFormat.format(totalIgst)})
Unpaid/Pending Bills Count: ${unpaidBills.length}
Total Customer Accounts: ${parties.length}

All Party Accounts Summary (Billed, Paid, Pending, Payment Status):
$partySummaryList

Complete Invoices Ledger (${bills.length} Invoices):
$allInvoicesSummary
''';

        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text': 'System: You are an expert GST Accountant AI for ${shop.name}.\n'
                        'IMPORTANT FORMATTING RULE: Do NOT use markdown asterisks (**) or backticks (`) in your response text.\n'
                        'Provide clean plain text with clear headings, clean bullet points, and exact customer ledger figures.\n\n'
                        'Context:\n$contextInfo\n\n'
                        'Question: $query\n\n'
                        'Answer concisely with clean plain text calculations:'
                  }
                ]
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          if (text != null && text.trim().isNotEmpty) {
            return text.trim().replaceAll('**', '').replaceAll('`', '');
          }
        }
      } catch (_) {
        // Fallback to local AI engine
      }
    }

    // Local Smart Rule-based AI Chat Response
    final q = query.toLowerCase();

    // 1. Check for specific Party / Customer by Name
    Party? matchedParty;
    for (final p in parties) {
      final nameLower = p.name.toLowerCase();
      final nameParts = nameLower.split(' ');
      if (q.contains(nameLower) || nameParts.any((part) => part.length >= 3 && q.contains(part))) {
        matchedParty = p;
        break;
      }
    }

    if (matchedParty != null) {
      final partyBills = bills.where((b) =>
        b.partyId == matchedParty!.id ||
        b.partyName.toLowerCase().contains(matchedParty!.name.toLowerCase())
      ).toList();

      final double partyBilled = partyBills.fold(0.0, (sum, b) => sum + b.grandTotal);
      final double partyPaid = partyBills.where((b) => b.paymentStatus == 'Paid').fold(0.0, (sum, b) => sum + b.grandTotal);
      final double partyPending = partyBilled - partyPaid;
      final bool isComplete = partyPending <= 0.01;

      final String statusBadge = isComplete
          ? '✅ PAYMENT IS COMPLETE (Fully Paid)'
          : '⚠️ PAYMENT IS NOT COMPLETE (Pending Balance: ${currencyFormat.format(partyPending)})';

      final String invoiceLines = partyBills.isEmpty
          ? '• No bills recorded for this party.'
          : partyBills.map((b) => '• ${b.invoiceNo} (${DateFormat('dd-MMM-yyyy').format(b.date)}): ${currencyFormat.format(b.grandTotal)} — [Status: ${b.paymentStatus}]').join('\n');

      return '👤 CUSTOMER LEDGER & PAYMENT STATUS: ${matchedParty.name}\n'
          '• State: ${matchedParty.state}\n'
          '• Total Billed Amount: ${currencyFormat.format(partyBilled)}\n'
          '• Amount Paid: ${currencyFormat.format(partyPaid)}\n'
          '• Pending Balance: ${currencyFormat.format(partyPending)}\n'
          '• Payment Completion: $statusBadge\n\n'
          '📋 Invoices (${partyBills.length} Bills):\n$invoiceLines';
    }

    // 2. Check for Specific Invoice Number (e.g., INV-2026-0001 or B001)
    for (final b in bills) {
      final invNoLower = b.invoiceNo.toLowerCase();
      final invClean = invNoLower.replaceAll('-', '');
      final qClean = q.replaceAll('-', '');

      if (q.contains(invNoLower) || q.contains(b.id.toLowerCase()) || (b.invoiceNo.length >= 4 && qClean.contains(invClean))) {
        final bool isPaid = b.paymentStatus == 'Paid';
        return '📄 INVOICE PAYMENT STATUS: ${b.invoiceNo}\n'
            '• Customer: ${b.partyName} (${b.partyState})\n'
            '• Invoice Date: ${DateFormat('dd-MMM-yyyy').format(b.date)}\n'
            '• Grand Total Amount: ${currencyFormat.format(b.grandTotal)}\n'
            '• Tax Amount: ${currencyFormat.format(b.totalTax)} (CGST: ${currencyFormat.format(b.totalCgst)}, SGST: ${currencyFormat.format(b.totalSgst)}, IGST: ${currencyFormat.format(b.totalIgst)})\n'
            '• Payment Completion: ${isPaid ? "✅ PAYMENT COMPLETE (Paid)" : "⚠️ PAYMENT NOT COMPLETE (Pending)"}\n'
            '• Payment Status: ${b.paymentStatus}';
      }
    }

    // 3. Overall Payment Completion Status Query
    if (q.contains('payment') || q.contains('complete') || q.contains('completed') || q.contains('paid') || q.contains('unpaid') || q.contains('due') || q.contains('pending')) {
      final paidBills = bills.where((b) => b.paymentStatus == 'Paid').toList();
      final pendingBills = bills.where((b) => b.paymentStatus != 'Paid').toList();
      final paidAmount = paidBills.fold(0.0, (sum, b) => sum + b.grandTotal);
      final pendingAmount = pendingBills.fold(0.0, (sum, b) => sum + b.grandTotal);

      final String pendingListStr = pendingBills.map((b) =>
        '• ${b.partyName} (${b.invoiceNo}): ${currencyFormat.format(b.grandTotal)} — [Status: ${b.paymentStatus}]'
      ).join('\n');

      return '💳 OVERALL PAYMENT COMPLETION SUMMARY:\n'
          '• Total Invoices: ${bills.length} Bills (Total Billed: ${currencyFormat.format(totalSales)})\n'
          '• Completed Payments (Paid): ${paidBills.length} Invoices (${currencyFormat.format(paidAmount)})\n'
          '• Pending / Unpaid Payments: ${pendingBills.length} Invoices (${currencyFormat.format(pendingAmount)})\n\n'
          '${pendingBills.isNotEmpty ? "⚠️ Pending Customer Accounts:\n$pendingListStr" : "🎉 All customer payments are 100% complete!"}';
    }

    // 4. Tax Query
    if (q.contains('tax') || q.contains('cgst') || q.contains('sgst') || q.contains('igst') || q.contains('gst')) {
      return '📊 GST TAX BREAKDOWN:\n'
          '• Total Tax Collected: ${currencyFormat.format(totalTax)}\n'
          '• Intra-State (CGST + SGST): ${currencyFormat.format(totalCgst + totalSgst)}\n'
          '• Inter-State (IGST): ${currencyFormat.format(totalIgst)}\n'
          '• Place of Supply Base: ${shop.state} (GSTIN: ${shop.gstin})';
    }

    // 5. Sales & Revenue Overview
    if (q.contains('sales') || q.contains('revenue') || q.contains('total') || q.contains('income')) {
      return '📈 SALES & REVENUE OVERVIEW:\n'
          '• Total Gross Revenue: ${currencyFormat.format(totalSales)}\n'
          '• Total Invoices Issued: ${bills.length} invoices\n'
          '• Average Invoice Value: ${currencyFormat.format(bills.isNotEmpty ? totalSales / bills.length : 0)}\n'
          '• Registered Customers: ${parties.length} party accounts';
    }

    // 6. Customer & Party General Overview
    if (q.contains('customer') || q.contains('party') || q.contains('top')) {
      final Map<String, double> partySales = {};
      for (final b in bills) {
        partySales[b.partyName] = (partySales[b.partyName] ?? 0.0) + b.grandTotal;
      }
      final sortedParties = partySales.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topParty = sortedParties.isNotEmpty ? sortedParties.first : null;

      return '👥 CUSTOMER INSIGHTS:\n'
          '• Total Registered Parties: ${parties.length}\n'
          '• Top Customer by Sales: ${topParty != null ? "${topParty.key} (${currencyFormat.format(topParty.value)})" : "N/A"}';
    }

    return '💡 GST WORKBENCH SUMMARY:\n'
        '• Total Revenue: ${currencyFormat.format(totalSales)} across ${bills.length} bills.\n'
        '• Total GST Collected: ${currencyFormat.format(totalTax)} (CGST/SGST: ${currencyFormat.format(totalCgst + totalSgst)}, IGST: ${currencyFormat.format(totalIgst)}).\n'
        '• Outstanding Bills: ${unpaidBills.length} invoices.';
  }

  /// 3. Smart HSN & GST Rate Suggestion Engine
  static Future<HsnSuggestion> suggestHsnAndGstRate({
    required String itemName,
    String? apiKey,
  }) async {
    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
        );

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text':
                        'Given product name "$itemName", suggest standard Indian HSN/SAC code (4 digits) and GST percentage slab (0, 5, 12, 18, 28). Return ONLY JSON: {"hsnCode": "8471", "gstPercent": 18, "category": "Electronics", "reasoning": "IT hardware"}'
                  }
                ]
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
          if (text != null) {
            final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
            if (jsonMatch != null) {
              final parsed = jsonDecode(jsonMatch.group(0)!);
              return HsnSuggestion(
                hsnCode: parsed['hsnCode'] as String? ?? '8471',
                gstPercent: (parsed['gstPercent'] as num? ?? 18.0).toDouble(),
                category: parsed['category'] as String? ?? 'General Goods',
                reasoning: parsed['reasoning'] as String? ?? 'Gemini AI Recommendation',
              );
            }
          }
        }
      } catch (_) {}
    }

    // Smart Local Category Engine
    final lower = itemName.toLowerCase();

    if (lower.contains('shirt') || lower.contains('pant') || lower.contains('cloth') || lower.contains('apparel') || lower.contains('cotton')) {
      return const HsnSuggestion(
        hsnCode: '6109',
        gstPercent: 5.0,
        category: 'Textiles & Apparel',
        reasoning: 'Apparel under ₹1,000 falls under 5% GST slab.',
      );
    }

    if (lower.contains('rice') || lower.contains('wheat') || lower.contains('mask') || lower.contains('food') || lower.contains('grain')) {
      return const HsnSuggestion(
        hsnCode: '1006',
        gstPercent: 5.0,
        category: 'Essential Groceries & Health',
        reasoning: 'Pre-packaged food grains and essential items are in 5% GST slab.',
      );
    }

    if (lower.contains('paper') || lower.contains('notebook') || lower.contains('pen') || lower.contains('mug') || lower.contains('bulb') || lower.contains('marker')) {
      return const HsnSuggestion(
        hsnCode: '4820',
        gstPercent: 12.0,
        category: 'Stationery & Houseware',
        reasoning: 'Paper products, pens, and LED bulbs fall under 12% GST slab.',
      );
    }

    if (lower.contains('car') || lower.contains('luxury') || lower.contains('ac') || lower.contains('tobacco') || lower.contains('aerated')) {
      return const HsnSuggestion(
        hsnCode: '8703',
        gstPercent: 28.0,
        category: 'Luxury & Automotive',
        reasoning: 'Luxury & automotive items fall under 28% peak GST slab.',
      );
    }

    // Default Electronics / IT
    return const HsnSuggestion(
      hsnCode: '8471',
      gstPercent: 18.0,
      category: 'Electronics & Hardware',
      reasoning: 'Standard electronic equipment and services fall under 18% GST slab.',
    );
  }

  /// 4. Anomaly & Duplicate Invoice Detector
  static List<BillAnomaly> detectBillAnomalies({
    required List<BillItem> items,
    required Party? party,
    required double discount,
    required List<Bill> existingBills,
  }) {
    final List<BillAnomaly> anomalies = [];

    if (items.isEmpty) return anomalies;

    // Check 1: High Discount Warning
    final double subtotal = items.fold(0.0, (sum, i) => sum + i.taxableAmt);
    if (subtotal > 0 && discount > (subtotal * 0.15)) {
      final percent = ((discount / subtotal) * 100).toStringAsFixed(1);
      anomalies.add(BillAnomaly(
        title: 'High Discount Alert ($percent%)',
        description: 'Applied discount of ₹$discount exceeds 15% of the total taxable amount (₹${subtotal.toStringAsFixed(2)}).',
        isWarning: true,
      ));
    }

    // Check 2: Potential Duplicate Bill Check
    if (party != null) {
      final grandTotal = items.fold(0.0, (sum, i) => sum + i.lineTotal) - discount;
      final duplicate = existingBills.where((b) {
        final isSameParty = b.partyId == party.id;
        final isCloseTotal = (b.grandTotal - grandTotal).abs() < 5.0;
        final isRecent = DateTime.now().difference(b.date).inHours < 24;
        return isSameParty && isCloseTotal && isRecent;
      }).firstOrNull;

      if (duplicate != null) {
        anomalies.add(BillAnomaly(
          title: 'Duplicate Invoice Warning',
          description: 'Invoice ${duplicate.invoiceNo} was recently created for customer ${party.name} with an identical amount of ₹${duplicate.grandTotal.toStringAsFixed(2)}.',
          isWarning: true,
        ));
      }
    }

    // Check 3: Rate Typo Deviation Check
    for (final item in items) {
      if (item.rate <= 0) {
        anomalies.add(BillAnomaly(
          title: 'Zero Rate Warning',
          description: 'Line item "${item.name}" has a rate of ₹0.00.',
          isWarning: true,
        ));
      }
    }

    return anomalies;
  }

  /// 5. AI Sales Forecast & Restock Intelligence
  static List<RestockSuggestion> forecastInventoryDemand({
    required List<Bill> bills,
    required List<Item> items,
  }) {
    final Map<String, int> totalQtySoldMap = {};

    for (final bill in bills) {
      for (final item in bill.items) {
        totalQtySoldMap[item.itemId] = (totalQtySoldMap[item.itemId] ?? 0) + item.qty;
      }
    }

    final List<RestockSuggestion> list = [];

    for (final item in items) {
      final sold = totalQtySoldMap[item.id] ?? 0;
      // Project demand based on past sales velocity
      final weeklyDemand = (sold / (bills.isEmpty ? 1 : (bills.length / 3))).ceil();
      final urgency = sold >= 10 ? 'High' : sold >= 4 ? 'Medium' : 'Normal';

      list.add(RestockSuggestion(
        item: item,
        totalSold: sold,
        projectedWeeklyDemand: weeklyDemand < 1 ? 2 : weeklyDemand,
        urgency: urgency,
      ));
    }

    list.sort((a, b) => b.totalSold.compareTo(a.totalSold));
    return list;
  }
}
