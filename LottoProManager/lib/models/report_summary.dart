class ReportSummary {
  const ReportSummary({
    required this.totalStake,
    required this.totalWinnings,
    required this.totalPaid,
  });

  final double totalStake;
  final double totalWinnings;
  final double totalPaid;

  double get totalProfit => totalStake - totalWinnings;
  double get pendingPayments {
    final pending = totalWinnings - totalPaid;
    return pending < 0 ? 0 : pending;
  }
}
