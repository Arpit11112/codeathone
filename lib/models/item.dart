class Item {
  final String id;
  final String name;
  final String? hsnCode;
  final double unitPrice;
  final double gstPercent;

  const Item({
    required this.id,
    required this.name,
    this.hsnCode,
    required this.unitPrice,
    required this.gstPercent,
  });

  Item copyWith({
    String? id,
    String? name,
    String? hsnCode,
    double? unitPrice,
    double? gstPercent,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      hsnCode: hsnCode ?? this.hsnCode,
      unitPrice: unitPrice ?? this.unitPrice,
      gstPercent: gstPercent ?? this.gstPercent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hsnCode': hsnCode,
      'unitPrice': unitPrice,
      'gstPercent': gstPercent,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      hsnCode: json['hsnCode'] as String?,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      gstPercent: (json['gstPercent'] as num).toDouble(),
    );
  }
}
