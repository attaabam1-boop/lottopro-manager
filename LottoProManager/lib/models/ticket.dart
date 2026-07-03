class Ticket {
  const Ticket({
    this.id,
    required this.customerId,
    required this.numbers,
    required this.playType,
    required this.stake,
    required this.drawDate,
    required this.status,
    this.winnings = 0,
  });

  final int? id;
  final int customerId;
  final String numbers;
  final String playType;
  final double stake;
  final DateTime drawDate;
  final String status;
  final double winnings;

  factory Ticket.fromMap(Map<String, Object?> map) {
    return Ticket(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      numbers: map['numbers'] as String,
      playType: map['play_type'] as String,
      stake: (map['stake'] as num).toDouble(),
      drawDate: DateTime.parse(map['draw_date'] as String),
      status: map['status'] as String,
      winnings: ((map['winnings'] as num?) ?? 0).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'numbers': numbers,
      'play_type': playType,
      'stake': stake,
      'draw_date': drawDate.toIso8601String(),
      'status': status,
      'winnings': winnings,
    };
  }

  Ticket copyWith({
    int? id,
    int? customerId,
    String? numbers,
    String? playType,
    double? stake,
    DateTime? drawDate,
    String? status,
    double? winnings,
  }) {
    return Ticket(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      numbers: numbers ?? this.numbers,
      playType: playType ?? this.playType,
      stake: stake ?? this.stake,
      drawDate: drawDate ?? this.drawDate,
      status: status ?? this.status,
      winnings: winnings ?? this.winnings,
    );
  }
}
