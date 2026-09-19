class ShopProfile {
  final String name;
  final String gstin;
  final String state;
  final String address;
  final String phone;
  final String email;
  final String bankName;
  final String accountNo;
  final String ifscCode;
  final String terms;

  const ShopProfile({
    required this.name,
    required this.gstin,
    required this.state,
    required this.address,
    required this.phone,
    required this.email,
    required this.bankName,
    required this.accountNo,
    required this.ifscCode,
    required this.terms,
  });

  ShopProfile copyWith({
    String? name,
    String? gstin,
    String? state,
    String? address,
    String? phone,
    String? email,
    String? bankName,
    String? accountNo,
    String? ifscCode,
    String? terms,
  }) {
    return ShopProfile(
      name: name ?? this.name,
      gstin: gstin ?? this.gstin,
      state: state ?? this.state,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      bankName: bankName ?? this.bankName,
      accountNo: accountNo ?? this.accountNo,
      ifscCode: ifscCode ?? this.ifscCode,
      terms: terms ?? this.terms,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gstin': gstin,
      'state': state,
      'address': address,
      'phone': phone,
      'email': email,
      'bankName': bankName,
      'accountNo': accountNo,
      'ifscCode': ifscCode,
      'terms': terms,
    };
  }

  factory ShopProfile.fromJson(Map<String, dynamic> json) {
    return ShopProfile(
      name: json['name'] as String,
      gstin: json['gstin'] as String,
      state: json['state'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      bankName: json['bankName'] as String,
      accountNo: json['accountNo'] as String,
      ifscCode: json['ifscCode'] as String,
      terms: json['terms'] as String,
    );
  }
}
