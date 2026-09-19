class Party {
  final String id;
  final String name;
  final String mobile;
  final String address;
  final String state;
  final String? gstin;
  final String? email;

  const Party({
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
    required this.state,
    this.gstin,
    this.email,
  });

  Party copyWith({
    String? id,
    String? name,
    String? mobile,
    String? address,
    String? state,
    String? gstin,
    String? email,
  }) {
    return Party(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      state: state ?? this.state,
      gstin: gstin ?? this.gstin,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': mobile,
      'address': address,
      'state': state,
      'gstin': gstin,
      'email': email,
    };
  }

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      id: json['id'] as String,
      name: json['name'] as String,
      mobile: json['mobile'] as String,
      address: json['address'] as String,
      state: json['state'] as String,
      gstin: json['gstin'] as String?,
      email: json['email'] as String?,
    );
  }
}
