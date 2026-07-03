class Payment {
  const Payment({
    this.id,
    required this.customerId,
    required this.amount,
    required this.paymentType,
    required this.date,
  });

  final int? id;
  final int customerId;
  final double amount;
  final String paymentType;
  final DateTime date;

  factory Payment.fromMap(Map<String, Object?> map) {
    return Payment(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentType: map['payment_type'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'payment_type': paymentType,
      'date': date.toIso8601String(),
    };
  }
}
