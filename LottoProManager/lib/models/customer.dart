class Customer {
  const Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.whatsapp,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final String phone;
  final String whatsapp;
  final DateTime createdAt;

  factory Customer.fromMap(Map<String, Object?> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      phone: map['phone'] as String,
      whatsapp: map['whatsapp'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'whatsapp': whatsapp,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? whatsapp,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
