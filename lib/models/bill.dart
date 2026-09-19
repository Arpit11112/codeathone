class BillItem {
  final String itemId;
  final String name;
  final String? hsnCode;
  final int qty;
  final double rate;
  final double gstPercent;
  final double taxableAmt;
  final double cgst;
  final double sgst;
  final double igst;

  const BillItem({
    required this.itemId,
    required this.name,
    this.hsnCode,
    required this.qty,
    required this.rate,
    required this.gstPercent,
    required this.taxableAmt,
    required this.cgst,
    required this.sgst,
    required this.igst,
  });

  double get lineTotal => taxableAmt + cgst + sgst + igst;

  BillItem copyWith({
    String? itemId,
    String? name,
    String? hsnCode,
    int? qty,
    double? rate,
    double? gstPercent,
    double? taxableAmt,
    double? cgst,
    double? sgst,
    double? igst,
  }) {
    return BillItem(
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      hsnCode: hsnCode ?? this.hsnCode,
      qty: qty ?? this.qty,
      rate: rate ?? this.rate,
      gstPercent: gstPercent ?? this.gstPercent,
      taxableAmt: taxableAmt ?? this.taxableAmt,
      cgst: cgst ?? this.cgst,
      sgst: sgst ?? this.sgst,
      igst: igst ?? this.igst,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'name': name,
      'hsnCode': hsnCode,
      'qty': qty,
      'rate': rate,
      'gstPercent': gstPercent,
      'taxableAmt': taxableAmt,
      'cgst': cgst,
      'sgst': sgst,
      'igst': igst,
    };
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      itemId: json['itemId'] as String,
      name: json['name'] as String,
      hsnCode: json['hsnCode'] as String?,
      qty: (json['qty'] as num).toInt(),
      rate: (json['rate'] as num).toDouble(),
      gstPercent: (json['gstPercent'] as num).toDouble(),
      taxableAmt: (json['taxableAmt'] as num).toDouble(),
      cgst: (json['cgst'] as num).toDouble(),
      sgst: (json['sgst'] as num).toDouble(),
      igst: (json['igst'] as num).toDouble(),
    );
  }
}

class Bill {
  final String id;
  final String invoiceNo;
  final DateTime date;
  final DateTime? dueDate;
  final String partyId;
  final String partyName;
  final String partyState;
  final String? partyGstin;
  final String partyAddress;
  final String partyMobile;
  final List<BillItem> items;
  final double subtotal;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double totalTax;
  final double discount;
  final double grandTotal;
  final String paymentStatus; // 'Paid', 'Unpaid', 'Partial'
  final double amountPaid;
  final double balanceDue;
  final DateTime? paymentDate;
  final String? paymentMethod; // 'UPI', 'Cash', 'Bank Transfer', 'Card'
  final String? notes;

  const Bill({
    required this.id,
    required this.invoiceNo,
    required this.date,
    this.dueDate,
    required this.partyId,
    required this.partyName,
    required this.partyState,
    this.partyGstin,
    required this.partyAddress,
    required this.partyMobile,
    required this.items,
    required this.subtotal,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalIgst,
    required this.totalTax,
    this.discount = 0.0,
    required this.grandTotal,
    this.paymentStatus = 'Paid',
    double? amountPaid,
    double? balanceDue,
    this.paymentDate,
    this.paymentMethod,
    this.notes,
  })  : amountPaid = amountPaid ?? (paymentStatus == 'Paid' ? grandTotal : (paymentStatus == 'Unpaid' ? 0.0 : grandTotal * 0.5)),
        balanceDue = balanceDue ?? (paymentStatus == 'Paid' ? 0.0 : (paymentStatus == 'Unpaid' ? grandTotal : grandTotal * 0.5));

  Bill copyWith({
    String? id,
    String? invoiceNo,
    DateTime? date,
    DateTime? dueDate,
    String? partyId,
    String? partyName,
    String? partyState,
    String? partyGstin,
    String? partyAddress,
    String? partyMobile,
    List<BillItem>? items,
    double? subtotal,
    double? totalCgst,
    double? totalSgst,
    double? totalIgst,
    double? totalTax,
    double? discount,
    double? grandTotal,
    String? paymentStatus,
    double? amountPaid,
    double? balanceDue,
    DateTime? paymentDate,
    String? paymentMethod,
    String? notes,
  }) {
    return Bill(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      partyState: partyState ?? this.partyState,
      partyGstin: partyGstin ?? this.partyGstin,
      partyAddress: partyAddress ?? this.partyAddress,
      partyMobile: partyMobile ?? this.partyMobile,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      totalCgst: totalCgst ?? this.totalCgst,
      totalSgst: totalSgst ?? this.totalSgst,
      totalIgst: totalIgst ?? this.totalIgst,
      totalTax: totalTax ?? this.totalTax,
      discount: discount ?? this.discount,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amountPaid: amountPaid ?? this.amountPaid,
      balanceDue: balanceDue ?? this.balanceDue,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNo': invoiceNo,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'partyId': partyId,
      'partyName': partyName,
      'partyState': partyState,
      'partyGstin': partyGstin,
      'partyAddress': partyAddress,
      'partyMobile': partyMobile,
      'items': items.map((x) => x.toJson()).toList(),
      'subtotal': subtotal,
      'totalCgst': totalCgst,
      'totalSgst': totalSgst,
      'totalIgst': totalIgst,
      'totalTax': totalTax,
      'discount': discount,
      'grandTotal': grandTotal,
      'paymentStatus': paymentStatus,
      'amountPaid': amountPaid,
      'balanceDue': balanceDue,
      'paymentDate': paymentDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      invoiceNo: json['invoiceNo'] as String,
      date: DateTime.parse(json['date'] as String),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'] as String) : null,
      partyId: json['partyId'] as String,
      partyName: json['partyName'] as String,
      partyState: json['partyState'] as String,
      partyGstin: json['partyGstin'] as String?,
      partyAddress: json['partyAddress'] as String,
      partyMobile: json['partyMobile'] as String,
      items: (json['items'] as List)
          .map((x) => BillItem.fromJson(x as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      totalCgst: (json['totalCgst'] as num).toDouble(),
      totalSgst: (json['totalSgst'] as num).toDouble(),
      totalIgst: (json['totalIgst'] as num).toDouble(),
      totalTax: (json['totalTax'] as num).toDouble(),
      discount: (json['discount'] as num? ?? 0.0).toDouble(),
      grandTotal: (json['grandTotal'] as num).toDouble(),
      paymentStatus: json['paymentStatus'] as String? ?? 'Paid',
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      balanceDue: (json['balanceDue'] as num?)?.toDouble(),
      paymentDate: json['paymentDate'] != null ? DateTime.tryParse(json['paymentDate'] as String) : null,
      paymentMethod: json['paymentMethod'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
